class CreateNotificationChannels < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_channels do |t|
      t.string :name, null: false
      t.string :channel_type, null: false, limit: 50
      t.jsonb :config, null: false
      t.boolean :enabled, default: true
      t.datetime :last_used_at
      t.text :last_error

      t.timestamps
    end
  end
end
