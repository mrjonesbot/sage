Sage.configure do |config|
  # Configure the AI service (options: :openai, :anthropic)
  config.ai_service = :anthropic

  # API Key Configuration
  # Priority order:
  # 1. Rails credentials: rails credentials:edit
  #    anthropic:
  #      api_key: your_key_here
  # 2. .env file: ANTHROPIC_API_KEY=your_key_here
  # 3. Direct configuration (not recommended for production):
  # config.anthropic_api_key = "your_key_here"

  # Model selection (optional, defaults to claude-3-opus-20240229)
  # config.anthropic_model = "claude-3-sonnet-20240229"

  # Safety and query settings
  config.allow_write_queries = false
  config.max_query_limit = 1000
  config.auto_save_queries = true
end
