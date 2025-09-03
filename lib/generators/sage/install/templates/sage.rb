Sage.configure do |config|
  # Configure the AI provider (options: :anthropic, :openai)
  config.provider = :anthropic
  # config.provider = :openai

  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  # config.openai_api_key = ENV["OPENAI_API_KEY"]
end
