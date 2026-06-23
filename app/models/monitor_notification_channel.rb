class MonitorNotificationChannel < ApplicationRecord
  belongs_to :monitor
  belongs_to :notification_channel

  validates :monitor_id, uniqueness: { scope: :notification_channel_id }
end
