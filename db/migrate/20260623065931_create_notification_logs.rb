class CreateNotificationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_logs do |t|
      t.references :incident, foreign_key: true
      t.references :notification_channel, null: false, foreign_key: true
      t.references :monitor, null: false, foreign_key: true
      t.string :status, null: false, limit: 20
      t.text :message
      t.text :error_message
      t.datetime :sent_at, null: false

      t.timestamps
    end

    add_index :notification_logs, :sent_at, order: { sent_at: :desc }
  end
end
