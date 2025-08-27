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
      context_parts << "\n\n## REFERENCE: COMMON QUERY PATTERNS\n"
      context_parts << "These ActiveRecord scopes show common query patterns used in the application:"

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
          model_info[:scopes].each do |scope|
            context_parts << "- #{scope}"
          end
        end
      end

      context_parts.join("\n")
    end

    private

    def collect_models_with_scopes
      models_with_scopes = []

      ActiveRecord::Base.descendants.each do |model|
        # Skip engine models and Blazer models
        next if model.name&.start_with?("Sage::", "Blazer::")
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
                  cleaned_sql = scope_sql.gsub(/^SELECT .* FROM/, "SELECT * FROM")
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

      models_with_scopes
    end
  end
end
