class MonitorTag < ApplicationRecord
  belongs_to :monitor, class_name: "SiteMonitor"
  belongs_to :tag
end
