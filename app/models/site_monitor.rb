class SiteMonitor < ApplicationRecord
  self.table_name = "monitors"
  belongs_to :monitor_group, optional: true

  has_many :check_results, dependent: :destroy
  has_many :incidents, dependent: :destroy
  has_many :monitor_notification_channels, dependent: :destroy
  has_many :notification_channels, through: :monitor_notification_channels
  has_many :monitor_tags, dependent: :destroy
  has_many :tags, through: :monitor_tags
  has_many :status_page_monitors, dependent: :destroy
  has_many :status_pages, through: :status_page_monitors
  has_many :response_time_stats, dependent: :destroy

  enum :status, { up: "up", down: "down", pending: "pending", paused: "paused" }, default: "pending"
  enum :monitor_type, {
    http: "http",
    keyword: "keyword",
    ping: "ping",
    port: "port",
    heartbeat: "heartbeat",
    ssl: "ssl",
    domain: "domain",
    dns: "dns",
    api: "api"
  }

  validates :name, presence: true
  validates :monitor_type, presence: true
  validates :interval, presence: true, numericality: { greater_than: 0 }
  validates :url, length: { maximum: 2048 }, allow_blank: true
  validates :heartbeat_token, uniqueness: true, allow_nil: true

  scope :active, -> { where(paused: false) }
  scope :paused, -> { where(paused: true) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_type, ->(type) { where(monitor_type: type) }

  def up?
    status == "up"
  end

  def down?
    status == "down"
  end

  def paused?
    paused
  end

  def active?
    !paused?
  end
end
