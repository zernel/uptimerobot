class AnnouncementUpdate < ApplicationRecord
  belongs_to :announcement

  enum :status, {
    investigating: "investigating",
    identified: "identified",
    monitoring: "monitoring",
    resolved: "resolved"
  }, allow_nil: true

  validates :content, presence: true
end
