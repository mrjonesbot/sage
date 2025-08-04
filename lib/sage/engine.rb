require "blazer/engine"
require "importmap-rails"
require "turbo-rails"
require "ruby_llm"

module Sage
  class Engine < ::Rails::Engine
    isolate_namespace Sage

    initializer "sage.importmap", before: "importmap" do |app|
      app.config.importmap.paths << root.join("config/importmap.rb") if Rails.application.respond_to?(:importmap)
    end

    initializer "sage.importmap_helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Importmap::ImportmapTagsHelper if defined?(Importmap::ImportmapTagsHelper)
      end
    end

    initializer "sage.ransack_helpers" do
      ActiveSupport.on_load(:action_view) do
        include Ransack::Helpers::FormHelper if defined?(Ransack::Helpers::FormHelper)
      end
    end

    initializer "sage.pagy_helpers" do
      ActiveSupport.on_load(:action_view) do
        include Pagy::Frontend if defined?(Pagy::Frontend)
      end
    end

    initializer "sage.turbo_helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Turbo::FramesHelper if defined?(Turbo::FramesHelper)
        helper Turbo::StreamsHelper if defined?(Turbo::StreamsHelper)
      end

      ActiveSupport.on_load(:action_view) do
        include Turbo::FramesHelper if defined?(Turbo::FramesHelper)
        include Turbo::StreamsHelper if defined?(Turbo::StreamsHelper)
      end
    end

    initializer "sage.ruby_llm" do
      RubyLLM.configure do |config|
        config.default_model = "claude-3-opus-20240229"

        # Determine API key with priority:
        # 1. Sage configuration (if explicitly set)
        # 2. Rails credentials (anthropic.api_key)
        # 3. Local .env file
        # Never use system ENV

        api_key = nil

        # Check if explicitly configured in Sage
        if Sage.configuration && Sage.configuration.anthropic_api_key
          api_key = Sage.configuration.anthropic_api_key
        end

        # Try Rails credentials
        if api_key.nil? && defined?(Rails.application.credentials)
          api_key = Rails.application.credentials.dig(:anthropic, :api_key)
        end

        # Try .env file
        if api_key.nil? && defined?(Rails.root)
          env_path = Rails.root.join(".env")
          if File.exist?(env_path)
            require "dotenv"
            env_vars = Dotenv.parse(env_path)
            api_key = env_vars["ANTHROPIC_API_KEY"]
          end
        end

        config.anthropic_api_key = api_key

        # Override model if configured
        if Sage.configuration && Sage.configuration.anthropic_model
          config.default_model = Sage.configuration.anthropic_model
        end
      end
    end

    initializer "sage.assets" do |app|
      # Add JavaScript path for Propshaft
      if defined?(Propshaft::Railtie)
        app.config.assets.paths << Engine.root.join("app/javascript")
        app.config.assets.paths << Engine.root.join("app/javascript/sage")
      end

      if app.config.respond_to?(:assets)
        # Blazer assets
        blazer_css_assets = [
          "blazer/selectize.css",
          "blazer/daterangepicker.css"
        ]

        blazer_js_assets = [
          "blazer/jquery.js",
          "blazer/rails-ujs.js",
          "blazer/stupidtable.js",
          "blazer/stupidtable-custom-settings.js",
          "blazer/jquery.stickytableheaders.js",
          "blazer/selectize.js",
          "blazer/highlight.min.js",
          "blazer/moment.js",
          "blazer/moment-timezone-with-data.js",
          "blazer/daterangepicker.js",
          "blazer/chart.umd.js",
          "blazer/chartjs-adapter-date-fns.bundle.js",
          "blazer/chartkick.js",
          "blazer/mapkick.bundle.js",
          "blazer/ace/ace.js",
          "blazer/ace/ext-language_tools.js",
          "blazer/ace/theme-twilight.js",
          "blazer/ace/mode-sql.js",
          "blazer/ace/snippets/text.js",
          "blazer/ace/snippets/sql.js",
          "blazer/Sortable.js",
          "blazer/bootstrap.js",
          "blazer/vue.global.prod.js",
          "blazer/routes.js",
          "blazer/queries.js",
          "blazer/fuzzysearch.js",
          "blazer/application.js"
        ]

        sage_assets = [
          "sage.js",
          "sage/application.css",
          "sage/controllers/search_controller.js",
          "sage/controllers/clipboard_controller.js"
        ]

        if defined?(Sprockets)
          if Sprockets::VERSION.to_i >= 4
            app.config.assets.precompile += blazer_css_assets + blazer_js_assets + sage_assets
          else
            # use a proc instead of a string
            app.config.assets.precompile << proc { |path| path =~ /\Asage\/.+\.css\z/ }
            app.config.assets.precompile << proc { |path| path =~ /\Asage\/.+\.js\z/ }
            app.config.assets.precompile << proc { |path| path =~ /\Asage\/controllers\/.+\.js\z/ }
            app.config.assets.precompile << proc { |path| path =~ /\Ablazer\/.+\.css\z/ }
            app.config.assets.precompile << proc { |path| path =~ /\Ablazer\/.+\.js\z/ }
          end
        else
          # For Propshaft
          app.config.assets.precompile += blazer_css_assets + blazer_js_assets + sage_assets
        end
      end
    end


    config.to_prepare do
      # Ensure we can access Blazer's models and controllers
      Dir.glob(Rails.root.join("app/models/blazer/*.rb")).each { |file| require_dependency file }

      # Load ransack configuration for Blazer::Query
      initializer_path = Engine.root.join("config/initializers/ransack.rb")
      load initializer_path if File.exist?(initializer_path)

      # Extend Blazer::Query with associations
      if defined?(Blazer::Query)
        Blazer::Query.class_eval do
          has_many :messages, class_name: "Sage::Message", foreign_key: :blazer_query_id, dependent: :destroy
        end
      end
    end

    # Autoload schemas
    config.autoload_paths += %W[#{root}/app/schemas]

    # Make Blazer available at the top level
    config.before_initialize do
      require "blazer"
    end
  end
end
