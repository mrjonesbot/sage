require "bundler/setup"
require "combustion"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"

logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDERR : nil)

Combustion.path = "test/internal"
Combustion.initialize! :active_record, :action_controller, :action_view do
  config.load_defaults Rails::VERSION::STRING.to_f
  config.action_controller.logger = logger
  config.active_record.logger = logger
  config.cache_store = :memory_store

  # fixes warning with adapter tests
  config.action_dispatch.show_exceptions = :none
end
