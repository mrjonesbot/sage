require "sage/version"
require "sage/engine"
require "blazer"
require "pagy"

module Sage
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    # attr_accessor :ai_service, :openai_api_key, :openai_model,
    # :anthropic_api_key, :anthropic_model,
    # :schema_context, :system_prompt,
    # :allow_write_queries, :max_query_limit,
    # :blazer_mount_path, :auto_save_queries

    attr_accessor :anthropic_model, :anthropic_api_key

    def initialize
      # @ai_service = :openai
      # @openai_model = "gpt-3.5-turbo"
      # @anthropic_model = "claude-sonnet-4-20250514"
      @anthropic_model = "claude-3-opus-20240229"
      # @allow_write_queries = false
      # @max_query_limit = 1000
      # @blazer_mount_path = "/blazer"
      # @auto_save_queries = false
      # @system_prompt = default_system_prompt
    end
  end
end
