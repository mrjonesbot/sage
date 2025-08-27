require "ruby_llm"
require_relative "database_schema_context"
require_relative "model_scopes_context"

module Sage
  class ReportProcessor
    include ActionView::RecordIdentifier

    attr_reader :query, :prompt, :stream_target_id, :raw_response_content

    def initialize(query:, prompt:, stream_target_id:)
      @query = query
      @prompt = prompt
      @stream_target_id = stream_target_id
    end

    def process
      response = generate_llm_response
      Rails.logger.info "LLM Response: #{response.inspect}"
      Rails.logger.info "LLM Response content: #{response.content.inspect}"
      @raw_response_content = response.content
      parsed_response = parse_response(response)
      Rails.logger.info "Parsed response: #{parsed_response.inspect}"

      {
        summary: parsed_response[:summary],
        sql: parsed_response[:sql]
      }
    end

    def system_prompt
      build_system_prompt
    end

    def database_schema_context
      Sage::DatabaseSchemaContext.new.build_context
    end

    def model_scopes_context
      Sage::ModelScopesContext.new.build_context
    end

    private

    def generate_llm_response
      RubyLLM.chat
        .with_instructions(system_prompt)
        .with_schema(Sage::ReportResponseSchema)
        .ask(prompt + ". #{structured_output}")
    end

    def parse_response(response)
      if response.content.is_a?(Hash) && response.content.key?("sql") && response.content.key?("summary")
        # Direct hash with sql and summary keys
        {
          summary: response.content["summary"],
          sql: response.content["sql"]
        }
      elsif response.content.is_a?(String)
        parse_json_response(response.content)
      else
        # Fallback for unexpected response format
        Rails.logger.warn "Unexpected response format: #{response.content.class}"
        {
          summary: "Unexpected response format. Please try again.",
          sql: nil
        }
      end
    end

    def parse_json_response(content)
      begin
        # First attempt: direct JSON parsing
        parsed_response = JSON.parse(content)
        {
          summary: parsed_response["summary"],
          sql: parsed_response["sql"]
        }
      rescue JSON::ParserError
        # Second attempt: fix malformed JSON by properly escaping newlines within quoted strings
        begin
          fixed_json = content.gsub(/"([^"]*)"/) do |match|
            # Escape newlines, tabs, and other control characters within the quoted string
            match.gsub(/\n/, '\\n').gsub(/\t/, '\\t').gsub(/\r/, '\\r')
          end

          parsed_response = JSON.parse(fixed_json)
          {
            summary: parsed_response["summary"],
            sql: parsed_response["sql"]
          }
        rescue JSON::ParserError => e
          # Final fallback: extract using regex patterns
          Rails.logger.warn "Failed to parse JSON even after fixing newlines: #{e.message}"

          # Extract SQL value (everything between "sql": " and the closing quote before comma or brace)
          sql_match = content.match(/"sql"\s*:\s*"((?:[^"\\]|\\.)*)"/m)
          sql = sql_match[1] if sql_match

          # Extract summary value
          summary_match = content.match(/"summary"\s*:\s*"((?:[^"\\]|\\.)*)"/m)
          summary = summary_match[1] if summary_match

          if sql.nil? || summary.nil?
            Rails.logger.error "Could not extract sql and summary from response"
            summary = "Failed to parse response. Please try again." if summary.nil?
          end

          {
            summary: summary || "Failed to parse response. Please try again.",
            sql: sql
          }
        end
      end
    end

    def structured_output
      <<~INSTRUCTION
        Return as a JSON object with sql and summary keys and no additional commentary.
      INSTRUCTION
    end

    def build_system_prompt
      prompt_parts = []

      # Detect database type
      database_type = detect_database_type

      # Base instruction optimized for LLM
      prompt_parts << <<~INSTRUCTION
        You are an expert SQL analyst helping users iteratively refine their database queries.

        DATABASE TYPE: #{database_type}

        Your task:
        1. Analyze the user's natural language request
        2. Determine if you should:
           a) Modify the most recent SQL query (from Previous Context if available)
           b) Modify the baseline query (from Current Query section)
           c) Create an entirely new query if the request is unrelated
        3. Generate the appropriate SQL query for #{database_type}
        4. Provide a clear explanation of what changed and why

        Response format (STRICT JSON):
        {
          "summary": "Explain what this query does and what changes were made from the previous version (if any)",
          "sql": "The complete SQL query statement"
        }

        IMPORTANT:#{' '}
        - Always return the COMPLETE query, not just the changes
        - When modifying existing queries, preserve the original intent while incorporating the requested changes
        - If the user asks for adjustments (e.g., "add a filter", "group by X", "sort differently"), modify the most recent query
        - If the user asks something completely new, create a fresh query

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
      INSTRUCTION

      # Add current query as baseline context
      if query.statement.present?
        prompt_parts << "\n\n## CURRENT QUERY (BASELINE)\n"
        prompt_parts << "The currently saved query that we're working with:\n"
        prompt_parts << "```sql\n#{query.statement}\n```"
        prompt_parts << "\nThis is the baseline query. You may modify or completely replace it based on the user's request.\n"
      end

      # Add latest message as context
      latest_message = query.messages.order(:created_at).last
      if latest_message
        prompt_parts << "\n\n## PREVIOUS CONTEXT\n"
        prompt_parts << "The most recent message from this conversation:\n"
        prompt_parts << "\nPrevious response: #{latest_message.body}" if latest_message.body.present?
        prompt_parts << "\nPrevious SQL: #{latest_message.statement}" if latest_message.statement.present?
        prompt_parts << "\n\nConsider this context when generating your response.\n"
      end

      # Add database schema
      schema_context = database_schema_context
      prompt_parts << schema_context if schema_context.present?

      # Add model scopes from host application
      scopes_context = model_scopes_context
      prompt_parts << scopes_context if scopes_context.present?

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
