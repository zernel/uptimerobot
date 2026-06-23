class MonitorGroup < ApplicationRecord
  has_many :monitors, dependent: :nullify

  validates :name, presence: true
end
