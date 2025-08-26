module Sage
  module ApplicationHelper
    include Pagy::Frontend

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
  end
end
