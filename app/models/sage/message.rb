module Sage
  class Message < ApplicationRecord
    belongs_to :blazer_query, class_name: "Blazer::Query", foreign_key: :blazer_query_id
    belongs_to :creator, optional: true, class_name: ::Blazer.user_class.to_s if ::Blazer.user_class

    validates :body, presence: true
  end
end
