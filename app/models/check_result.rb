class CheckResult < ApplicationRecord
  belongs_to :monitor, class_name: "SiteMonitor"

  enum :status, { up: "up", down: "down" }

  validates :status, presence: true
  validates :checked_at, presence: true

  scope :recent, -> { order(checked_at: :desc) }
  scope :for_period, ->(start_time, end_time) { where(checked_at: start_time..end_time) }
  scope :up, -> { where(status: "up") }
  scope :down, -> { where(status: "down") }
end
