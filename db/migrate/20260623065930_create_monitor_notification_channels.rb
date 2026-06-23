class CreateMonitorNotificationChannels < ActiveRecord::Migration[8.1]
  def change
    create_table :monitor_notification_channels do |t|
      t.references :monitor, null: false, foreign_key: true
      t.references :notification_channel, null: false, foreign_key: true
      t.boolean :notify_on_up, default: true
      t.boolean :notify_on_down, default: true
      t.boolean :notify_on_ssl_expiry, default: true
      t.boolean :notify_on_domain_expiry, default: true

      t.timestamps
    end

    add_index :monitor_notification_channels, [:monitor_id, :notification_channel_id], unique: true, name: 'idx_monitor_notification_channels_unique'
  end
end
