require_relative "lib/sage/version"

Gem::Specification.new do |spec|
  spec.name          = "sage-rails"
  spec.version       = Sage::VERSION
  spec.summary       = "LLM powered business intelligence. Build SQL reports using natural language."
  spec.homepage      = "https://github.com/mrjonesbot/sage"
  spec.license       = "MIT"

  spec.author        = "Nathan Jones"
  spec.email         = "natejones@hey.com"

  spec.files         = Dir["*.{md,txt}", "{app,config,lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 3.2"

  spec.add_dependency "railties", ">= 7.1"
  spec.add_dependency "activerecord", ">= 7.1"
  spec.add_dependency "blazer", ">= 3.0"
  spec.add_dependency "turbo-rails"
  spec.add_dependency "importmap-rails"
  spec.add_dependency "ransack"
  spec.add_dependency "pagy"
  spec.add_dependency "ruby_llm", "~> 1.6"
  spec.add_dependency "ruby_llm-schema"
end
