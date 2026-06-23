class StatusPageMonitor < ApplicationRecord
  belongs_to :status_page
  belongs_to :monitor

  validates :status_page_id, uniqueness: { scope: :monitor_id }
end
