class CreateMaintenanceWindows < ActiveRecord::Migration[8.1]
  def change
    create_table :maintenance_windows do |t|
      t.string :name, null: false
      t.text :description
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :recurrence, limit: 20
      t.datetime :recurrence_end_at
      t.jsonb :monitor_ids, default: '[]'

      t.timestamps
    end

    add_index :maintenance_windows, :starts_at
    add_index :maintenance_windows, :ends_at
  end
end
