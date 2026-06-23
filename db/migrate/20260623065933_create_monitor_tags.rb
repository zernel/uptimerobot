class CreateMonitorTags < ActiveRecord::Migration[8.1]
  def change
    create_table :monitor_tags do |t|
      t.references :monitor, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
