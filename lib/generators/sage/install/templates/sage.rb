Sage.configure do |config|
  # AI Service Configuration
  # Uncomment and configure your preferred AI service
  
  # OpenAI Configuration
  # config.ai_service = :openai
  # config.openai_api_key = ENV["OPENAI_API_KEY"]
  # config.openai_model = "gpt-4" # or "gpt-3.5-turbo"
  
  # Anthropic Claude Configuration
  # config.ai_service = :anthropic
  # config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  # config.anthropic_model = "claude-3-opus-20240229"
  
  # Database Schema Configuration
  # Provide table definitions to improve SQL generation accuracy
  # config.schema_context = <<~SCHEMA
  #   Tables:
  #   - users (id, email, name, created_at, updated_at)
  #   - orders (id, user_id, total, status, created_at)
  #   - products (id, name, price, category, stock)
  #   - order_items (id, order_id, product_id, quantity, price)
  # SCHEMA
  
  # Prompt Configuration
  # Customize the system prompt for SQL generation
  # config.system_prompt = <<~PROMPT
  #   You are a SQL expert. Generate PostgreSQL queries based on the user's natural language questions.
  #   Always return valid SQL that can be executed directly.
  #   Include appropriate JOINs, WHERE clauses, and aggregations as needed.
  #   Format the SQL nicely with proper indentation.
  # PROMPT
  
  # Safety Configuration
  # Restrict certain SQL operations
  config.allow_write_queries = false # Set to true to allow INSERT/UPDATE/DELETE
  config.max_query_limit = 1000 # Maximum LIMIT for SELECT queries
  
  # Integration Configuration
  # Configure how Sage integrates with Blazer
  config.blazer_mount_path = "/blazer" # Where Blazer is mounted in your app
end