class CreateStatusPageMonitors < ActiveRecord::Migration[8.1]
  def change
    create_table :status_page_monitors do |t|
      t.references :status_page, null: false, foreign_key: true
      t.references :monitor, null: false, foreign_key: true
      t.integer :sort_order

      t.timestamps
    end
  end
end
