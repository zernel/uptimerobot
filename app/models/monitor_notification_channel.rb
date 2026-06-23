class MonitorNotificationChannel < ApplicationRecord
  belongs_to :monitor, class_name: "SiteMonitor"
  belongs_to :notification_channel

  validates :monitor_id, uniqueness: { scope: :notification_channel_id }
end
