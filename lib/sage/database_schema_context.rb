module Sage
  class DatabaseSchemaContext
    def initialize(data_source_name = "main")
      @data_source_name = data_source_name
    end

    def self.call(data_source_name = "main")
      new(data_source_name).build_context
    end

    def build_context
      context_parts = []
      context_parts << "\n\n## DATABASE SCHEMA\n"
      context_parts << "Available tables and their columns (use these exact names in your queries):\n"

      begin
        data_source = Blazer.data_sources[@data_source_name]
        if data_source && data_source.respond_to?(:schema)
          schema_info = data_source.schema

          # Format the schema array into readable text
          if schema_info.is_a?(Array)
            schema_info.each do |table_info|
              next unless table_info.is_a?(Hash)

              schema_name = table_info[:schema] || "public"
              table_name = table_info[:table]
              columns = table_info[:columns] || []

              context_parts << "\n### Table: `#{schema_name}.#{table_name}`"
              context_parts << "Columns:"

              columns.each do |column|
                if column.is_a?(Hash)
                  col_name = column[:name]
                  data_type = column[:data_type]
                  context_parts << "  - `#{col_name}` (#{data_type})"
                end
              end
            end
          else
            # Fallback to original behavior if schema is not in expected format
            context_parts << "```"
            context_parts << schema_info.to_s
            context_parts << "```"
          end
        end
      rescue => e
        Rails.logger.warn "Could not load database schema: #{e.message}"
        return nil
      end

      context_parts.join("\n")
    end
  end
end
