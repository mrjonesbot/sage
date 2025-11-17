module Sage
  module ApplicationHelper
    # Provide access to Sage engine routes
    def sage
      Sage::Engine.routes.url_helpers
    end

    def messages_grouped_by_day(messages)
      messages.group_by { |message| message.created_at.to_date }
             .sort_by { |date, _| date }
    end

    def format_message_date(date)
      case date
      when Date.current
        "Today"
      when Date.current - 1
        "Yesterday"
      else
        if date.year == Date.current.year
          date.strftime("%B %d")
        else
          date.strftime("%B %d, %Y")
        end
      end
    end

    # Support both Pagy 9.x and 43.x
    def pagy_navigation(pagy_object)
      if defined?(Pagy::Backend)
        # Pagy 9.x uses pagy_nav helper
        pagy_nav(pagy_object)
      else
        # Pagy 43.x uses instance method
        pagy_object.series_nav
      end
    end
  end
end
