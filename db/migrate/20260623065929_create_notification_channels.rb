class CreateNotificationChannels < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_channels do |t|
      t.string :name
      t.string :channel_type
      t.jsonb :config
      t.boolean :enabled
      t.datetime :last_used_at
      t.text :last_error

      t.timestamps
    end
  end
end
