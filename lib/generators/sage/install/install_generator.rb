require "rails/generators"

module Sage
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install Sage engine and mount it in your application"

      def install_blazer
        # Check if Blazer is already installed by looking for migration
        blazer_installed = Dir.glob("db/migrate/*_install_blazer.rb").any?

        if blazer_installed
          say "Blazer already installed, skipping...", :yellow
        else
          say "Installing Blazer...", :green
          generate "blazer:install"
        end
      end

      def add_routes
        # Remove existing Blazer route if present
        routes_file = "config/routes.rb"
        if File.exist?(routes_file)
          routes_content = File.read(routes_file)

          # Pattern to match Blazer mount (with various formatting)
          blazer_route_pattern = /^\s*mount\s+Blazer::Engine\s*,\s*at:\s*['"]blazer['"]\s*$/

          if routes_content.match?(blazer_route_pattern)
            # Remove the Blazer route
            gsub_file routes_file, blazer_route_pattern, ""
            say "Removed existing Blazer route", :yellow
          end
        end

        # Mount Sage (which includes Blazer functionality)
        route 'mount Sage::Engine => "/sage"'
        say "Mounted Sage at /sage", :green
      end

      def create_initializer
        template "sage.rb", "config/initializers/sage.rb"
      end

      def create_migrations
        say "Creating Sage database migrations...", :green

        # Generate timestamp for migration
        timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")

        # Create the migration file
        migration_file = "db/migrate/#{timestamp}_create_sage_messages.rb"
        create_file migration_file do
          <<~RUBY
            class CreateSageMessages < ActiveRecord::Migration[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]
              def change
                create_table :sage_messages do |t|
                  t.references :blazer_query
                  t.references :creator
                  t.string :body

                  t.timestamps
                end
              end
            end
          RUBY
        end

        say "Created migration for sage_messages table", :green
      end

      def add_javascript_integration
        say "Configuring JavaScript integration...", :green

        # Update application.js to register Sage controllers
        app_js_path = "app/javascript/application.js"
        if File.exist?(app_js_path)
          app_js_content = File.read(app_js_path)
          unless app_js_content.include?("sage")
            append_to_file app_js_path do
              <<~JS

                // Import and register Sage controllers
                import { registerControllers } from "sage"
                registerControllers(application)
              JS
            end
            say "Updated application.js to register Sage controllers", :green
          else
            say "Sage controllers already registered in application.js", :yellow
          end
        else
          say "Could not find app/javascript/application.js - you'll need to manually import Sage controllers", :yellow
        end
      end

      def add_stylesheets
        # Stylesheets are served directly from the engine via the asset pipeline
        # No need to copy or require them - they're automatically available
        say "Sage stylesheets will be served from the engine", :green
      end

      def display_instructions
        say "\n" + "="*50, :green
        say "Sage installation complete!", :green
        say "="*50, :green
        say "\nNext steps:"
        say "1. Run 'bundle install' to install dependencies"
        say "2. Run 'rails db:migrate' to create Blazer tables"
        say "3. Configure your AI service in config/initializers/sage.rb"
        say "4. Visit #{root_url}sage to start using Sage"
        say "\nFor AI integration, you'll need to:"
        say "- Set up an Anthropic API key (or OpenAI if preferred)"
        say "- Add the API key to Rails credentials or .env file"
        say "- Configure database schema context for better SQL generation"
      end

      private

      def root_url
        "http://localhost:3000/"
      end
    end
  end
end
