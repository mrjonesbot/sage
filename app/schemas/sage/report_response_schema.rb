require "ruby_llm/schema"

module Sage
  class ReportResponseSchema < RubyLLM::Schema
    string :sql, description: "Generated SQL by user prompt"
    string :summary, description: "Natural language summary of generated report"
  end
end
