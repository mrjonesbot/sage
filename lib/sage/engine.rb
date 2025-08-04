module Sage
  class Engine < ::Rails::Engine
    isolate_namespace Sage

    initializer "sage.assets" do |app|
      app.config.assets.paths << root.join("app/assets/stylesheets")
      app.config.assets.paths << root.join("app/javascript")
      app.config.assets.precompile += %w[sage/application.css]
    end

    initializer "sage.importmap", before: "importmap" do |app|
      app.config.importmap.paths << root.join("config/importmap.rb")
      app.config.importmap.cache_sweepers << root.join("app/javascript")
    end

    config.to_prepare do
      # Ensure we can access Blazer's models and controllers
      Dir.glob(Rails.root.join("app/models/blazer/*.rb")).each { |file| require_dependency file }
    end
  end
end
