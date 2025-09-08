Rails.application.config.after_initialize do
  if defined?(Sage)
    Sage.configure do |config|
      # Configure the AI service (options: :openai, :anthropic)
      config.provider = :anthropic

      # Other configuration options
      # config.allow_write_queries = false
      # config.max_query_limit = 1000
      # config.auto_save_queries = true
    end
  end
end
