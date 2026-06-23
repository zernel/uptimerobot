class ResponseTimeStat < ApplicationRecord
  belongs_to :monitor

  enum :period_type, { hourly: "hourly", daily: "daily" }

  validates :period_type, presence: true
  validates :period_start, presence: true
  validates :period_start, uniqueness: { scope: [:monitor_id, :period_type] }

  scope :recent, -> { order(period_start: :desc) }
end
