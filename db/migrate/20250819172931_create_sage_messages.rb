class CreateSageMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :sage_messages do |t|
      t.references :blazer_query
      t.references :creator
      t.string :body

      t.timestamps
    end
  end
end
