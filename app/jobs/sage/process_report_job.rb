require "sage/report_processor"

module Sage
  class ProcessReportJob < ActiveJob::Base
    include ActionView::RecordIdentifier
    include Sage::Engine.routes.url_helpers

    def perform(prompt, query_id:, stream_target_id:)
      query = Blazer::Query.find(query_id)

      # Ensure we have the proper routing context for broadcasts
      self.class.default_url_options = Rails.application.routes.default_url_options

      Turbo::StreamsChannel.broadcast_append_to(
        "messages",
        target: dom_id(query, "messages"),
        partial: "sage/queries/streaming_message",
        locals: { stream_target_id:, content: "Thinking..." }
      )

      # Use the ReportProcessor to handle the LLM interaction and parsing
      processor = ReportProcessor.new(
        query: query,
        prompt: prompt,
        stream_target_id: stream_target_id
      )

      result = processor.process
      summary = result[:summary]
      sql = result[:sql]

      puts "SUMMARY: #{summary}"
      # Handle empty summary
      summary = "I couldn't generate a response. Please try again." if summary.blank?

      ai_message = query.messages.create!(body: summary, statement: sql)

      Turbo::StreamsChannel.broadcast_replace_to(
        "messages",
        target: stream_target_id,
        partial: "sage/queries/message",
        locals: { message: ai_message, stream_target_id: stream_target_id }
      )

      Turbo::StreamsChannel.broadcast_replace_to(
        "statements",
        target: dom_id(query, "statement-box"),
        partial: "sage/queries/statement_box",
        locals: { query: query, statement: sql, form_url: run_queries_path }
      )

      # Auto-submit the form after the statement_box renders
      Turbo::StreamsChannel.broadcast_append_to(
        "statements",
        target: "body",
        html: "<script>
          setTimeout(() => {
            // Wait for ACE editor to be fully initialized
            const checkAndSubmit = () => {
              const form = document.querySelector('##{dom_id(query, "statement-box")} form');
              const hiddenField = document.querySelector('#query_statement');

              if (form && hiddenField && hiddenField.value && window.aceEditor) {
                form.submit();
              } else {
                // Retry after another 100ms if not ready
                setTimeout(checkAndSubmit, 100);
              }
            };
            checkAndSubmit();
          }, 200);
        </script>"
      )

      true
    end
  end
end
