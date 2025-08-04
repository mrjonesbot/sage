require "rails/generators"

module Sage
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install Sage engine and mount it in your application"

      def add_route
        route 'mount Sage::Engine => "/sage"'
        say "Mounted Sage at /sage", :green
      end

      def create_initializer
        template "sage.rb", "config/initializers/sage.rb"
      end

      def add_javascript_dependencies
        if File.exist?("config/importmap.rb")
          append_to_file "config/importmap.rb" do
            <<~RUBY
              
              # Sage engine pins
              pin "sage/application", to: "sage/application.js"
            RUBY
          end
          say "Added Sage to importmap", :green
        end
      end

      def add_stylesheets
        if File.exist?("app/assets/stylesheets/application.css")
          append_to_file "app/assets/stylesheets/application.css" do
            <<~CSS
              
              /*
               *= require sage/application
               */
            CSS
          end
          say "Added Sage stylesheets", :green
        elsif File.exist?("app/assets/stylesheets/application.scss")
          append_to_file "app/assets/stylesheets/application.scss" do
            <<~SCSS
              
              @import "sage/application";
            SCSS
          end
          say "Added Sage stylesheets", :green
        end
      end

      def display_instructions
        say "\n" + "="*50, :green
        say "Sage installation complete!", :green
        say "="*50, :green
        say "\nNext steps:"
        say "1. Run 'bundle install' to install dependencies"
        say "2. Ensure Blazer is installed and configured"
        say "3. Configure your AI service in config/initializers/sage.rb"
        say "4. Visit #{root_url}sage to start using Sage"
        say "\nFor AI integration, you'll need to:"
        say "- Set up OpenAI, Anthropic, or another LLM API"
        say "- Configure database schema access for better SQL generation"
        say "- Customize the prompt templates in the initializer"
      end

      private

      def root_url
        "http://localhost:3000/"
      end
    end
  end
end