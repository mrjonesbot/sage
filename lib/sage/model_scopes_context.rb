module Sage
  class ModelScopesContext
    def initialize
      # Nothing to initialize for now
    end

    def self.call
      new.build_context
    end

    def build_context
      context_parts = []
      context_parts << "\n\n## AVAILABLE SCOPES → SQL MAPPINGS\n"
      context_parts << "CRITICAL: Use these scopes to understand how to query the data!"
      context_parts << "Each scope name shows the SQL conditions it generates."
      context_parts << "When a user's request matches a scope's intent, use that scope's SQL pattern.\n"

      # Get all ActiveRecord models from the host application
      # Safely attempt to eager load, but continue if there are issues
      begin
        Rails.application.eager_load! if Rails.env.development?
      rescue Zeitwerk::NameError => e
        Rails.logger.warn "Could not eager load all files: #{e.message}"
      end

      models_with_scopes = collect_models_with_scopes

      # Format the model scopes nicely
      if models_with_scopes.any?
        models_with_scopes.each do |model_info|
          context_parts << "\n### #{model_info[:name]} (table: `#{model_info[:table]}`)"
          context_parts << "Scopes and their SQL equivalents:"
          model_info[:scopes].each do |scope|
            context_parts << scope
          end
        end
      end

      context_parts.join("\n")
    end

    private

    def collect_models_with_scopes
      models_with_scopes = []

      # Find all model files in the app/models directory
      model_files = Dir.glob(Rails.root.join("app/models/**/*.rb"))

      model_files.each do |file_path|
        # Skip concern files and other non-model files
        next if file_path.include?("/concerns/")

        # Read the file content
        file_content = File.read(file_path)

        # Extract model name from file path
        model_name = File.basename(file_path, ".rb").camelize

        # Find all scope definitions using regex
        # Match various scope patterns:
        # scope :active, -> { where(active: true) }
        # scope :recent, lambda { where("created_at > ?", 1.week.ago) }
        # scope :by_role, ->(role) { where(role: role) }
        scope_patterns = [
          # Pattern 1: scope :name, -> { ... } or -> (...) { ... }
          /scope\s+:(\w+)\s*,\s*->\s*(?:\([^)]*\))?\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}/m,
          # Pattern 2: scope :name, lambda { ... }
          /scope\s+:(\w+)\s*,\s*lambda\s*(?:\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\})/m,
          # Pattern 3: Simple one-liner scopes
          /scope\s+:(\w+)\s*,\s*(.+?)$/
        ]

        scope_matches = []
        scope_patterns.each do |pattern|
          matches = file_content.scan(pattern)
          matches.each do |match|
            scope_name = match[0]
            scope_body = match[1] || ""
            # Avoid duplicate entries
            unless scope_matches.any? { |s| s[0] == scope_name }
              scope_matches << [ scope_name, scope_body ]
            end
          end
        end

        if scope_matches.any?
          # Try to get the actual model class and table name
          begin
            model_class = model_name.constantize
            table_name = model_class.table_name rescue model_name.tableize
          rescue => e
            table_name = model_name.tableize
            model_class = nil
          end

          model_info = {
            name: model_name,
            table: table_name,
            scopes: []
          }

          scope_matches.each do |match|
            scope_name = match[0]
            scope_body = match[1]

            if scope_body
              # Try to extract SQL-like patterns from the scope body
              # Look for where conditions, joins, etc.
              sql_hint = extract_sql_from_scope_body(scope_body)
              model_info[:scopes] << "  • `#{scope_name}` → SQL: `#{sql_hint}`"
            else
              # Scope might be using a lambda with parameters or complex logic
              model_info[:scopes] << "  • `#{scope_name}` → (check model file for implementation)"
            end
          end

          models_with_scopes << model_info if model_info[:scopes].any?
        end
      end

      models_with_scopes
    end

    def extract_sql_from_scope_body(scope_body)
      # Clean up the scope body
      cleaned = scope_body.strip

      sql_parts = []

      # Extract WHERE conditions
      if cleaned =~ /where\s*\(["']([^"']+)["'](?:,\s*(.+?))?\)/
        # String SQL with potential parameters
        sql_parts << "WHERE #{$1}"
      elsif cleaned =~ /where\s*\(([^)]+)\)/
        # Hash or conditions
        where_conditions = $1.strip
        # Convert Ruby hash syntax to SQL-like
        where_conditions = where_conditions.gsub(/(\w+):\s*(\w+)/, '\1 = \2')
        where_conditions = where_conditions.gsub(/(\w+):\s*["']([^"']+)["']/, '\1 = "\2"')
        where_conditions = where_conditions.gsub(/(\w+):\s*(true|false|nil)/, '\1 = \2')
        sql_parts << "WHERE #{where_conditions}"
      elsif cleaned =~ /where\.not\s*\(([^)]+)\)/
        # WHERE NOT conditions
        not_conditions = $1.strip
        not_conditions = not_conditions.gsub(/(\w+):\s*/, '\1 != ')
        sql_parts << "WHERE NOT (#{not_conditions})"
      end

      # Extract JOINs
      if cleaned =~ /joins?\s*\(:?(\w+)\)/
        sql_parts << "JOIN #{$1}"
      elsif cleaned =~ /includes?\s*\(:?(\w+)\)/
        sql_parts << "LEFT JOIN #{$1}"
      end

      # Extract ORDER
      if cleaned =~ /order\s*\(["']([^"']+)["']\)/
        sql_parts << "ORDER BY #{$1}"
      elsif cleaned =~ /order\s*\(([^)]+)\)/
        order_clause = $1.strip
        order_clause = order_clause.gsub(/(\w+):\s*:?(asc|desc)/i, '\1 \2')
        sql_parts << "ORDER BY #{order_clause}"
      end

      # Extract LIMIT
      if cleaned =~ /limit\s*\((\d+)\)/
        sql_parts << "LIMIT #{$1}"
      end

      # If we found SQL parts, join them
      if sql_parts.any?
        sql_parts.join(" ")
      else
        # Check if it's a simple scope referencing another scope
        if cleaned =~ /^(\w+)$/
          "(uses #{$1} scope)"
        else
          # Return a truncated version if we can't parse it
          cleaned.length > 60 ? "#{cleaned[0..60]}..." : cleaned
        end
      end
    end
  end
end
