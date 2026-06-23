class IncidentComment < ApplicationRecord
  belongs_to :incident

  validates :content, presence: true
end
