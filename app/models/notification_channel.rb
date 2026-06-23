class NotificationChannel < ApplicationRecord
  has_many :monitor_notification_channels, dependent: :destroy
  has_many :monitors, through: :monitor_notification_channels, source: :monitor
  has_many :notification_logs, dependent: :destroy

  enum :channel_type, {
    email: "email",
    slack: "slack",
    mattermost: "mattermost",
    feishu: "feishu"
  }

  validates :name, presence: true
  validates :channel_type, presence: true
  validates :config, presence: true

  scope :enabled, -> { where(enabled: true) }
  scope :by_type, ->(type) { where(channel_type: type) }
end
