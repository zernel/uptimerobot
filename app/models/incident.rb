class Incident < ApplicationRecord
  belongs_to :monitor, class_name: "SiteMonitor"

  has_many :incident_comments, dependent: :destroy
  has_many :notification_logs, dependent: :nullify

  enum :status, { ongoing: "ongoing", resolved: "resolved" }, default: "ongoing"

  validates :started_at, presence: true

  scope :ongoing, -> { where(status: "ongoing") }
  scope :resolved, -> { where(status: "resolved") }
  scope :recent, -> { order(started_at: :desc) }
  scope :for_period, ->(start_time, end_time) { where(started_at: start_time..end_time) }

  def resolve!
    update!(status: :resolved, resolved_at: Time.current)
  end

  def duration_seconds
    end_time = resolved_at || Time.current
    (end_time - started_at).to_i
  end
end
