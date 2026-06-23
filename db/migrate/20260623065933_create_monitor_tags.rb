class CreateMonitorTags < ActiveRecord::Migration[8.1]
  def change
    create_table :monitor_tags, id: false do |t|
      t.references :monitor, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
    end

    add_index :monitor_tags, [:monitor_id, :tag_id], unique: true
  end
end
