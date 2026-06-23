class NotificationLog < ApplicationRecord
  belongs_to :incident, optional: true
  belongs_to :notification_channel
  belongs_to :monitor, class_name: "SiteMonitor"

  enum :status, { sent: "sent", failed: "failed" }

  validates :status, presence: true
  validates :sent_at, presence: true

  scope :recent, -> { order(sent_at: :desc) }
  scope :for_period, ->(start_time, end_time) { where(sent_at: start_time..end_time) }
end
