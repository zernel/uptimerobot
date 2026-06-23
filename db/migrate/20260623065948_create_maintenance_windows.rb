class CreateMaintenanceWindows < ActiveRecord::Migration[8.1]
  def change
    create_table :maintenance_windows do |t|
      t.string :name
      t.text :description
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :recurrence
      t.datetime :recurrence_end_at
      t.jsonb :monitor_ids

      t.timestamps
    end
  end
end
