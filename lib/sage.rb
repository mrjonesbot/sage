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
    attr_accessor :anthropic_api_key, :anthropic_model, :open_ai_key, :open_ai_model, :provider

    def initialize
      @provider = :anthropic
      @anthropic_model = "claude-3-opus-20240229"
      @open_ai_model = "gpt-4"
    end
  end
end
