class AddStatementToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :sage_messages, :statement, :text
  end
end
