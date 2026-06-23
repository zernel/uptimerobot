class Tag < ApplicationRecord
  has_many :monitor_tags, dependent: :destroy
  has_many :monitors, through: :monitor_tags

  validates :name, presence: true, uniqueness: true
end
