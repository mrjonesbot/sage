# Sage

Sage is a Rails engine that enhances [Blazer](https://github.com/ankane/blazer) by adding an AI-powered SQL query generator. It allows users to generate SQL queries from natural language questions, making data exploration more accessible.

## Features

- Natural language to SQL query generation
- Integration with Blazer for query execution
- Support for multiple AI providers (OpenAI, Anthropic)
- Configurable safety restrictions
- Turbo/Hotwire-powered interface

## Installation

Add Sage to your application's Gemfile:

```ruby
gem "blazer", ">= 3.0"
gem "sage"
```

Run bundle install:
```bash
$ bundle install
```

Run the install generator:
```bash
$ rails generate sage:install
```

This will:
- Mount Sage at `/sage` in your routes
- Create an initializer at `config/initializers/sage.rb`
- Add necessary JavaScript and CSS dependencies

## Configuration

Configure Sage in `config/initializers/sage.rb`:

```ruby
Sage.configure do |config|
  # Choose your AI service
  config.ai_service = :openai
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  config.openai_model = "gpt-4"
  
  # Or use Anthropic Claude
  # config.ai_service = :anthropic
  # config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  # config.anthropic_model = "claude-3-opus-20240229"
  
  # Provide your database schema for better results
  config.schema_context = <<~SCHEMA
    Tables:
    - users (id, email, name, created_at, updated_at)
    - orders (id, user_id, total, status, created_at)
    - products (id, name, price, category, stock)
  SCHEMA
  
  # Safety settings
  config.allow_write_queries = false
  config.max_query_limit = 1000
end
```

## Usage

1. Navigate to `/sage` in your application
2. Enter a natural language question (e.g., "Show me the top 10 customers by revenue in the last 30 days")
3. Review the generated SQL query
4. Click "Run in Blazer" to execute the query

## AI Service Integration

To use Sage, you'll need to implement the AI service integration in your application. Here's a basic example:

```ruby
# app/services/sage_ai_service.rb
class SageAiService
  def self.generate_sql(question)
    case Sage.configuration.ai_service
    when :openai
      generate_with_openai(question)
    when :anthropic
      generate_with_anthropic(question)
    else
      raise "Unknown AI service: #{Sage.configuration.ai_service}"
    end
  end
  
  private
  
  def self.generate_with_openai(question)
    # Implement OpenAI API call
    # Return generated SQL string
  end
  
  def self.generate_with_anthropic(question)
    # Implement Anthropic API call
    # Return generated SQL string
  end
end
```

Then update the controller to use your service:

```ruby
# In your app, override the generate_sql_from_question method
module Sage
  class QueriesController
    private
    
    def generate_sql_from_question(question)
      SageAiService.generate_sql(question)
    end
  end
end
```

## Development

After checking out the repo, run:

```bash
$ bundle install
$ cd test/dummy
$ rails db:create
$ rails db:migrate
$ rails server
```

Visit http://localhost:3000/sage to see the engine in action.

## Testing

```bash
$ rails test
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).