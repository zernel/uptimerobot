class CreateNotificationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_logs do |t|
      t.references :incident, null: false, foreign_key: true
      t.references :notification_channel, null: false, foreign_key: true
      t.references :monitor, null: false, foreign_key: true
      t.string :status
      t.text :message
      t.text :error_message
      t.datetime :sent_at

      t.timestamps
    end
  end
end
