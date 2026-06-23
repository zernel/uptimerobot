class CreateMonitorNotificationChannels < ActiveRecord::Migration[8.1]
  def change
    create_table :monitor_notification_channels do |t|
      t.references :monitor, null: false, foreign_key: true
      t.references :notification_channel, null: false, foreign_key: true
      t.boolean :notify_on_up
      t.boolean :notify_on_down
      t.boolean :notify_on_ssl_expiry
      t.boolean :notify_on_domain_expiry

      t.timestamps
    end
  end
end
