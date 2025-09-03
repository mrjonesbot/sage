Sage.configure do |config|
  # Configure the AI provider (options: :anthropic, :openai)
  config.provider = :anthropic

  # API Key Configuration
  # Priority order:
  # 1. Rails credentials: rails credentials:edit
  #    anthropic:
  #      api_key: your_key_here
  #    openai:
  #      api_key: your_key_here
  # 2. .env file: ANTHROPIC_API_KEY=your_key_here or OPENAI_API_KEY=your_key_here
  # 3. Direct configuration (not recommended for production):
  # config.anthropic_api_key = "your_key_here"
  # config.open_ai_key = "your_key_here"

  # Model selection (optional)
  # For Anthropic (defaults to claude-3-opus-20240229):
  # config.anthropic_model = "claude-3-sonnet-20240229"
  # For OpenAI (defaults to gpt-4):
  # config.open_ai_model = "gpt-3.5-turbo"
end
