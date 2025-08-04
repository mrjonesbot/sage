require "sage/version"
require "sage/engine"

module Sage
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :ai_service, :openai_api_key, :openai_model,
                  :anthropic_api_key, :anthropic_model,
                  :schema_context, :system_prompt,
                  :allow_write_queries, :max_query_limit,
                  :blazer_mount_path

    def initialize
      @ai_service = :openai
      @openai_model = "gpt-3.5-turbo"
      @anthropic_model = "claude-3-opus-20240229"
      @allow_write_queries = false
      @max_query_limit = 1000
      @blazer_mount_path = "/blazer"
      @system_prompt = default_system_prompt
    end

    private

    def default_system_prompt
      <<~PROMPT
        You are a SQL expert assistant. Generate SQL queries based on natural language questions.
        Return only valid, executable SQL. Use proper JOINs and aggregations as needed.
        Format the output with clear indentation.
      PROMPT
    end
  end
end
