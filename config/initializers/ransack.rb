require "ransack"

# Configure Ransack for Blazer models
Rails.application.config.after_initialize do
  # Ensure Blazer is loaded first
  require "blazer" if defined?(Blazer)

  # Extend Blazer::Query with Ransack capabilities
  if defined?(Blazer::Query)
    # First, ensure Ransack is included in the model
    unless Blazer::Query.respond_to?(:ransack)
      Blazer::Query.send(:extend, Ransack::Adapters::ActiveRecord::Base)
    end

    Blazer::Query.class_eval do
      # Define which attributes can be searched
      def self.ransackable_attributes(auth_object = nil)
        %w[name description statement creator_id created_at updated_at status]
      end

      # Define which associations can be searched
      def self.ransackable_associations(auth_object = nil)
        associations = %w[checks audits dashboard_queries dashboards]
        associations << "creator" if Blazer.user_class
        associations
      end

      # Optional: Define custom ransack scopes
      scope :search_by_keywords, ->(keywords) {
        sanitized = connection.quote_string(keywords.to_s)
        where("name ILIKE '%#{sanitized}%' OR description ILIKE '%#{sanitized}%' OR statement ILIKE '%#{sanitized}%'")
      } if !respond_to?(:search_by_keywords)

      # Make the custom scope available to ransack
      def self.ransackable_scopes(auth_object = nil)
        %i[search_by_keywords]
      end
    end
  end

  # Extend Blazer::Dashboard with Ransack capabilities
  if defined?(Blazer::Dashboard)
    # First, ensure Ransack is included in the model
    unless Blazer::Dashboard.respond_to?(:ransack)
      Blazer::Dashboard.send(:extend, Ransack::Adapters::ActiveRecord::Base)
    end

    Blazer::Dashboard.class_eval do
      # Define which attributes can be searched
      def self.ransackable_attributes(auth_object = nil)
        %w[name creator_id created_at updated_at]
      end

      # Define which associations can be searched
      def self.ransackable_associations(auth_object = nil)
        associations = %w[dashboard_queries queries]
        associations << "creator" if Blazer.user_class
        associations
      end
    end
  end
end

# Also configure in to_prepare for development reloading
Rails.application.config.to_prepare do
  if defined?(Blazer::Query)
    # Ensure Ransack is included
    unless Blazer::Query.respond_to?(:ransack)
      Blazer::Query.send(:extend, Ransack::Adapters::ActiveRecord::Base)
    end

    unless Blazer::Query.respond_to?(:ransackable_attributes)
      Blazer::Query.class_eval do
        def self.ransackable_attributes(auth_object = nil)
          %w[name description statement creator_id created_at updated_at status]
        end

        def self.ransackable_associations(auth_object = nil)
          %w[creator checks audits dashboard_queries dashboards]
        end

        def self.ransackable_scopes(auth_object = nil)
          %i[search_by_keywords]
        end
      end
    end
  end

  if defined?(Blazer::Dashboard)
    # Ensure Ransack is included
    unless Blazer::Dashboard.respond_to?(:ransack)
      Blazer::Dashboard.send(:extend, Ransack::Adapters::ActiveRecord::Base)
    end

    unless Blazer::Dashboard.respond_to?(:ransackable_attributes)
      Blazer::Dashboard.class_eval do
        def self.ransackable_attributes(auth_object = nil)
          %w[name creator_id created_at updated_at]
        end

        def self.ransackable_associations(auth_object = nil)
          associations = %w[dashboard_queries queries]
          associations << "creator" if Blazer.user_class
          associations
        end
      end
    end
  end

  if defined?(Blazer::Check)
    # Ensure Ransack is included
    unless Blazer::Check.respond_to?(:ransack)
      Blazer::Check.send(:extend, Ransack::Adapters::ActiveRecord::Base)
    end

    unless Blazer::Check.respond_to?(:ransackable_attributes)
      Blazer::Check.class_eval do
        def self.ransackable_attributes(auth_object = nil)
          %w[emails slack_channels check_type schedule state message last_run_at invert creator_id created_at updated_at query_id]
        end

        def self.ransackable_associations(auth_object = nil)
          associations = %w[query]
          associations << "creator" if Blazer.user_class
          associations
        end
      end
    end
  end

  # Extend Blazer::Check with Ransack capabilities
  if defined?(Blazer::Check)
    # First, ensure Ransack is included in the model
    unless Blazer::Check.respond_to?(:ransack)
      Blazer::Check.send(:extend, Ransack::Adapters::ActiveRecord::Base)
    end

    Blazer::Check.class_eval do
      # Define which attributes can be searched
      def self.ransackable_attributes(auth_object = nil)
        %w[emails slack_channels check_type schedule state message last_run_at invert creator_id created_at updated_at query_id]
      end

      # Define which associations can be searched
      def self.ransackable_associations(auth_object = nil)
        associations = %w[query]
        associations << "creator" if Blazer.user_class
        associations
      end
    end
  end
end
