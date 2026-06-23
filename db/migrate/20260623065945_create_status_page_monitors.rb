class CreateStatusPageMonitors < ActiveRecord::Migration[8.1]
  def change
    create_table :status_page_monitors do |t|
      t.references :status_page, null: false, foreign_key: true
      t.references :monitor, null: false, foreign_key: true
      t.integer :sort_order, default: 0

      t.timestamps
    end

    add_index :status_page_monitors, [:status_page_id, :monitor_id], unique: true, name: 'idx_status_page_monitors_unique'
  end
end
