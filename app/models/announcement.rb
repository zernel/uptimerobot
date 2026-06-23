class Announcement < ApplicationRecord
  belongs_to :status_page

  has_many :announcement_updates, dependent: :destroy

  enum :status, {
    investigating: "investigating",
    identified: "identified",
    monitoring: "monitoring",
    resolved: "resolved"
  }, default: "investigating"

  validates :title, presence: true
  validates :content, presence: true
  validates :started_at, presence: true

  scope :active, -> { where.not(status: "resolved") }
  scope :resolved, -> { where(status: "resolved") }
  scope :recent, -> { order(started_at: :desc) }
end
