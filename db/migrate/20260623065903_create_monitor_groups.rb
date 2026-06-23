class CreateMonitorGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :monitor_groups do |t|
      t.string :name
      t.text :description
      t.integer :sort_order

      t.timestamps
    end
  end
end
