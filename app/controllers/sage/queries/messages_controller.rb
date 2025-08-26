
module Sage
  module Queries
    class MessagesController < BaseController
      before_action :set_query

      def index
        page = params[:page] || 1

        # For reverse infinite scroll, we want:
        # Page 1: Most recent messages (to show at bottom initially)
        # Page 2: Older messages (to prepend when scrolling up)
        # Page 3: Even older messages, etc.

        base_query = @query.messages.order(created_at: :desc)
        @pagy, messages = pagy(base_query, page: page, overflow: :last_page)

        # For page 1 (initial load), show newest messages in chronological order (oldest first)
        # For page 2+, keep reverse chronological order for prepending
        if page.to_i == 1
          @messages = messages.reverse # Show oldest first for initial display
        else
          @messages = messages # Keep newest first for prepending
        end

        respond_to do |format|
          format.html # For turbo_frame initial load
          format.turbo_stream # For infinite scroll pagination
        end
      end

      def create
        @message = @query.messages.create!(body: params[:statement])
        creator_id = blazer_user.present? ? blazer_user.id : 0

        @message.creator_id = creator_id
        @message.save!
        @message.reload

        stream_target_id = SecureRandom.hex(8)

        Sage::ProcessReportJob.perform_later(
          @message.body,
          query_id: @message.blazer_query.id,
          stream_target_id:
        )

        # Check if we need a new day separator
        @need_day_separator = @query.messages.where(
          "DATE(created_at) = ?",
          @message.created_at.to_date
        ).count == 1
      end

      private

      def set_query
        @query = Blazer::Query.find(params[:query_id])
      end
    end
  end
end
