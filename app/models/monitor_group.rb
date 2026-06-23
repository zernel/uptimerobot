class MonitorGroup < ApplicationRecord
  has_many :monitors, class_name: "SiteMonitor", foreign_key: :monitor_group_id, dependent: :nullify

  validates :name, presence: true
end
