require "blazer/engine"
require "importmap-rails"
require "turbo-rails"
require "ruby_llm"
require "ransack"

module Sage
  class Engine < ::Rails::Engine
    isolate_namespace Sage

    initializer "sage.importmap", before: "importmap" do |app|
      if Rails.application.respond_to?(:importmap)
        # Only add our importmap if it hasn't been added already
        importmap_path = root.join("config/importmap.rb")
        unless app.config.importmap.paths.include?(importmap_path)
          app.config.importmap.paths << importmap_path
        end
      end
    end

    initializer "sage.importmap_helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Importmap::ImportmapTagsHelper if defined?(Importmap::ImportmapTagsHelper)
      end
    end

    initializer "sage.ransack_helpers", after: "ransack" do
      # Ensure Ransack is fully loaded with its helpers
      require "ransack" unless defined?(::Ransack)

      # Load Ransack's ActionView extensions which include the helpers
      if defined?(::Ransack)
        require "ransack/helpers/form_helper" if !defined?(Ransack::Helpers)
      end

      ActiveSupport.on_load(:action_controller_base) do
        if defined?(Ransack::Helpers::FormHelper)
          helper Ransack::Helpers::FormHelper
        end
      end

      ActiveSupport.on_load(:action_view) do
        if defined?(Ransack::Helpers::FormHelper)
          include Ransack::Helpers::FormHelper
        end
      end

      # Also add to our base controller immediately if it's loaded
      if defined?(Sage::BaseController) && defined?(Ransack::Helpers::FormHelper)
        Sage::BaseController.helper Ransack::Helpers::FormHelper
      end
    end

    # Support both Pagy 9.x (Frontend) and Pagy 43.x (instance methods)
    initializer "sage.pagy_helpers" do
      ActiveSupport.on_load(:action_view) do
        if defined?(Pagy::Frontend)
          # Pagy 9.x uses Frontend module
          include Pagy::Frontend
        end
        # Pagy 43.x uses instance methods on @pagy objects, no module needed
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
        # Determine provider and configure accordingly
        provider = (Sage.configuration&.provider || :anthropic).to_sym

        case provider
        when :anthropic
          config.default_model = Sage.configuration&.anthropic_model || "claude-3-opus-20240229"

          # Determine API key with priority:
          # 1. Sage configuration (if explicitly set)
          # 2. Rails credentials
          # 3. Local .env file
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

        when :openai
          config.default_model = Sage.configuration&.open_ai_model || "gpt-4"

          # Determine API key with priority:
          # 1. Sage configuration (if explicitly set)
          # 2. Rails credentials
          # 3. Local .env file
          api_key = nil

          # Check if explicitly configured in Sage
          if Sage.configuration && Sage.configuration.open_ai_key
            api_key = Sage.configuration.open_ai_key
          end

          # Try Rails credentials
          if api_key.nil? && defined?(Rails.application.credentials)
            api_key = Rails.application.credentials.dig(:openai, :api_key)
          end

          # Try .env file
          if api_key.nil? && defined?(Rails.root)
            env_path = Rails.root.join(".env")
            if File.exist?(env_path)
              require "dotenv"
              env_vars = Dotenv.parse(env_path)
              api_key = env_vars["OPENAI_API_KEY"]
            end
          end

          config.openai_api_key = api_key
        end
      end
    end

    initializer "sage.assets" do |app|
      # Add JavaScript paths based on asset pipeline
      if app.config.respond_to?(:assets)
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
          "sage/application.js",
          "sage/application.css",
          "sage/controllers/search_controller.js",
          "sage/controllers/clipboard_controller.js",
          "sage/controllers/select_controller.js",
          "sage/controllers/dashboard_controller.js",
          "sage/controllers/reverse_infinite_scroll_controller.js",
          "sage/controllers/query_toggle_controller.js",
          "sage/controllers/variables_controller.js"
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
      # Ensure Ransack is loaded
      require "ransack" if defined?(::Ransack).nil?

      # Ensure we can access Blazer's models and controllers
      Dir.glob(Rails.root.join("app/models/blazer/*.rb")).each { |file| require_dependency file }

      # Load ransack configuration for Blazer::Query
      initializer_path = Engine.root.join("config/initializers/ransack.rb")
      load initializer_path if File.exist?(initializer_path)

      # Extend Blazer::Query with associations
      if defined?(Blazer::Query)
        # Ensure Ransack is available for Blazer::Query
        unless Blazer::Query.respond_to?(:ransack)
          Blazer::Query.send(:extend, Ransack::Adapters::ActiveRecord::Base)
        end

        Blazer::Query.class_eval do
          has_many :messages, class_name: "Sage::Message", foreign_key: :blazer_query_id, dependent: :destroy

          # Define ransackable attributes if not already defined
          unless respond_to?(:ransackable_attributes)
            def self.ransackable_attributes(auth_object = nil)
              %w[name description statement creator_id created_at updated_at status]
            end

            def self.ransackable_associations(auth_object = nil)
              %w[creator checks audits dashboard_queries dashboards messages]
            end
          end
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
