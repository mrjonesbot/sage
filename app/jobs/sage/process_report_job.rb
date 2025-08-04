require "ruby_llm"

module Sage
  class ProcessReportJob < ActiveJob::Base
    include ActionView::RecordIdentifier
    include Sage::Engine.routes.url_helpers

    def perform(prompt, query_id:, stream_target_id:)
      query = Blazer::Query.find(query_id)

      # Ensure we have the proper routing context for broadcasts
      self.class.default_url_options = Rails.application.routes.default_url_options

      Turbo::StreamsChannel.broadcast_append_to(
        "messages",
        target: dom_id(query, "messages"),
        partial: "sage/queries/streaming_message",
        locals: { stream_target_id:, content: "Thinking..." }
      )

      system_prompt = build_system_prompt
      response = RubyLLM.chat
        .with_schema(Sage::ReportResponseSchema)
        .with_instructions(system_prompt)
        .ask(prompt)

      summary = response.content["summary"]
      sql = response.content["sql"]

      puts "SUMMARY: #{summary}"
      # Handle empty summary
      summary = "I couldn't generate a response. Please try again." if summary.blank?

      ai_message = query.messages.create!(body: summary)

      Turbo::StreamsChannel.broadcast_replace_to(
        "messages",
        target: stream_target_id,
        partial: "sage/queries/message",
        locals: { message: ai_message, stream_target_id: stream_target_id }
      )

      Turbo::StreamsChannel.broadcast_replace_to(
        "statements",
        target: dom_id(query, "statement-box"),
        partial: "sage/queries/statement_box",
        locals: { query: query, statement: sql }
      )

      # Auto-submit the form after the statement_box renders
      Turbo::StreamsChannel.broadcast_append_to(
        "statements",
        target: "body",
        html: "<script>
          setTimeout(() => {
            // Wait for ACE editor to be fully initialized
            const checkAndSubmit = () => {
              const form = document.querySelector('##{dom_id(query, "statement-box")} form');
              const hiddenField = document.querySelector('#query_statement');

              if (form && hiddenField && hiddenField.value && window.aceEditor) {
                form.submit();
              } else {
                // Retry after another 100ms if not ready
                setTimeout(checkAndSubmit, 100);
              }
            };
            checkAndSubmit();
          }, 200);
        </script>"
      )

      # TODO broadcast response message
      # TODO broadcast sql update

      puts "SUMMARY: #{response.content['summary']}"
      puts "SQL: #{response.content['sql']}"

      true
    end

    private

    def build_system_prompt
      prompt_parts = []
      
      # Detect database type
      database_type = detect_database_type
      
      # Base instruction optimized for LLM
      prompt_parts << <<~INSTRUCTION
        You are an expert SQL analyst helping users query their database.
        
        DATABASE TYPE: #{database_type}
        
        Your task:
        1. Analyze the user's natural language request
        2. Generate an appropriate SQL query for #{database_type}
        3. Provide a clear explanation of what the query does
        
        Response format (STRICT JSON):
        {
          "summary": "A clear, concise explanation of what this query retrieves and why it answers the user's question",
          "sql": "The SQL query statement"
        }
        
        Guidelines:
        - Write efficient, readable SQL using #{database_type}-specific syntax
        - Use meaningful table aliases and column names
        - Include comments in complex queries
        - Prefer JOINs over subqueries when appropriate
        - Consider performance implications for large datasets
        - Use the available model scopes as reference for common query patterns
        - Ensure all table and column names match the schema exactly
        - Handle NULL values appropriately
        - Use proper data type casting when needed
        - Follow #{database_type} best practices and syntax conventions
        
        IMPORTANT: Return ONLY valid JSON with the exact keys "summary" and "sql". No additional text or explanation outside the JSON structure.
      INSTRUCTION
      
      # Add database schema
      prompt_parts << "\n\n## DATABASE SCHEMA\n"
      prompt_parts << "Available tables and their columns (use these exact names in your queries):\n"
      begin
        data_source = Blazer.data_sources['main']
        if data_source && data_source.respond_to?(:schema)
          schema_info = data_source.schema
          prompt_parts << "```"
          prompt_parts << schema_info.to_s
          prompt_parts << "```"
        end
      rescue => e
        Rails.logger.warn "Could not load database schema: #{e.message}"
      end
      
      # Add model scopes from host application
      prompt_parts << "\n\n## REFERENCE: COMMON QUERY PATTERNS\n"
      prompt_parts << "These ActiveRecord scopes show common query patterns used in the application:"
      
      # Get all ActiveRecord models from the host application
      Rails.application.eager_load! if Rails.env.development?
      
      models_with_scopes = []
      
      ActiveRecord::Base.descendants.each do |model|
        # Skip engine models and Blazer models
        next if model.name&.start_with?('Sage::', 'Blazer::')
        next if model.abstract_class?
        
        # Get all scopes defined on the model
        scopes = model.scopes.keys rescue []
        
        if scopes.any?
          model_info = {
            name: model.name,
            table: model.table_name,
            scopes: []
          }
          
          scopes.each do |scope_name|
            # Try to get scope SQL if possible
            begin
              # For scopes without arguments, try to get the SQL
              if model.method(scope_name).arity == 0
                scope_sql = model.send(scope_name).to_sql rescue nil
                if scope_sql
                  # Clean up the SQL for readability
                  cleaned_sql = scope_sql.gsub(/^SELECT .* FROM/, 'SELECT * FROM')
                  model_info[:scopes] << "#{scope_name}: #{cleaned_sql}"
                else
                  model_info[:scopes] << scope_name.to_s
                end
              else
                # Scope requires arguments
                model_info[:scopes] << "#{scope_name} (parameterized)"
              end
            rescue => e
              model_info[:scopes] << scope_name.to_s
            end
          end
          
          models_with_scopes << model_info
        end
      end
      
      # Format the model scopes nicely
      if models_with_scopes.any?
        models_with_scopes.each do |model_info|
          prompt_parts << "\n### #{model_info[:name]} (table: `#{model_info[:table]}`)"
          model_info[:scopes].each do |scope|
            prompt_parts << "- #{scope}"
          end
        end
      end
      
      prompt_parts << "\n\n## QUERY GENERATION RULES"
      prompt_parts << "1. Match table and column names EXACTLY as shown in the schema"
      prompt_parts << "2. Use the scope patterns as guidance for common filters and joins"
      prompt_parts << "3. Generate ONE query that best answers the user's request"
      prompt_parts << "4. Optimize for clarity and performance"
      
      prompt_parts.join("\n")
    end

    def detect_database_type
      adapter_name = ActiveRecord::Base.connection.adapter_name.downcase
      
      case adapter_name
      when /postgresql/, /postgis/
        "PostgreSQL"
      when /mysql/, /mysql2/
        "MySQL"
      when /sqlite/
        "SQLite3"
      when /sqlserver/, /mssql/
        "SQL Server"
      when /oracle/
        "Oracle"
      else
        adapter_name.capitalize
      end
    end
  end
end
