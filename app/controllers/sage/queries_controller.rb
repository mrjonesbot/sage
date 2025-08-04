module Sage
  class QueriesController < ApplicationController
    def new
      @query = OpenStruct.new(question: "", sql: "")
    end

    def create
      @query = OpenStruct.new(query_params)
      
      # Stub for AI SQL generation - this is where you'll integrate your AI service
      @query.sql = generate_sql_from_question(@query.question)
      
      respond_to do |format|
        format.turbo_stream
        format.html { render :new }
      end
    end

    def run
      @query = OpenStruct.new(query_params)
      
      # This would integrate with Blazer to run the query
      # For now, we'll just redirect to Blazer with the query
      redirect_to blazer_path_with_query(@query.sql)
    end

    private

    def query_params
      params.require(:query).permit(:question, :sql)
    end

    def generate_sql_from_question(question)
      # Placeholder for AI integration
      # In production, this would call your AI service (OpenAI, Anthropic, etc.)
      "-- AI generated SQL for: #{question}\n" +
      "-- TODO: Integrate with AI service\n" +
      "SELECT 'Please configure AI service' as message;"
    end

    def blazer_path_with_query(sql)
      # Construct Blazer URL with the SQL query
      # This assumes Blazer is mounted at /blazer in the host app
      main_app.blazer_path + "?query[statement]=" + CGI.escape(sql)
    end
  end
end