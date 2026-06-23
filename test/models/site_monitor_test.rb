require "test_helper"

class SiteMonitorTest < ActiveSupport::TestCase
  # ── Validations ──────────────────────────────────────────────────

  test "requires name" do
    monitor = SiteMonitor.new(monitor_type: "http", interval: 60)
    assert_not monitor.valid?
    assert_includes monitor.errors[:name], "can't be blank"
  end

  test "requires monitor_type" do
    monitor = SiteMonitor.new(name: "Test", interval: 60)
    monitor.monitor_type = nil
    assert_not monitor.valid?
    assert_includes monitor.errors[:monitor_type], "can't be blank"
  end

  test "requires interval" do
    monitor = SiteMonitor.new(name: "Test", monitor_type: "http", interval: nil)
    assert_not monitor.valid?
    assert_includes monitor.errors[:interval], "can't be blank"
  end

  test "interval must be greater than 0" do
    monitor = SiteMonitor.new(name: "Test", monitor_type: "http", interval: 0)
    assert_not monitor.valid?
    assert_includes monitor.errors[:interval], "must be greater than 0"

    monitor.interval = -1
    assert_not monitor.valid?
    assert_includes monitor.errors[:interval], "must be greater than 0"
  end

  test "valid with positive interval" do
    monitor = SiteMonitor.new(name: "Test", monitor_type: "http", interval: 60)
    assert monitor.valid?
  end

  test "url length must not exceed 2048" do
    monitor = site_monitors(:http_monitor)
    monitor.url = "https://example.com/" + "a" * 2030
    assert_not monitor.valid?
    assert_includes monitor.errors[:url], "is too long (maximum is 2048 characters)"
  end

  test "url can be blank" do
    monitor = SiteMonitor.new(name: "Ping", monitor_type: "ping", interval: 60, url: "")
    assert monitor.valid?
  end

  test "heartbeat_token must be unique" do
    monitor = SiteMonitor.new(
      name: "Another Heartbeat",
      monitor_type: "heartbeat",
      interval: 3600,
      heartbeat_token: site_monitors(:heartbeat_monitor).heartbeat_token
    )
    assert_not monitor.valid?
    assert_includes monitor.errors[:heartbeat_token], "has already been taken"
  end

  test "heartbeat_token can be nil" do
    monitor = SiteMonitor.new(name: "Test", monitor_type: "http", interval: 60, heartbeat_token: nil)
    assert monitor.valid?
  end

  # ── Associations ─────────────────────────────────────────────────

  test "belongs_to monitor_group is optional" do
    monitor = SiteMonitor.new(name: "Test", monitor_type: "http", interval: 60, monitor_group: nil)
    assert monitor.valid?
  end

  test "belongs_to monitor_group" do
    monitor = site_monitors(:http_monitor)
    monitor.update!(monitor_group: monitor_groups(:web_group))
    assert_equal monitor_groups(:web_group), monitor.reload.monitor_group
  end

  test "has_many check_results with dependent destroy" do
    monitor = site_monitors(:http_monitor)
    assert_includes monitor.check_results, check_results(:recent_success)

    assert_difference("CheckResult.count", -monitor.check_results.count) do
      monitor.destroy
    end
  end

  test "has_many incidents with dependent destroy" do
    monitor = site_monitors(:http_monitor)
    assert_includes monitor.incidents, incidents(:ongoing_incident)

    assert_difference("Incident.count", -monitor.incidents.count) do
      monitor.destroy
    end
  end

  test "has_many tags through monitor_tags" do
    monitor = site_monitors(:http_monitor)
    monitor.tags << tags(:production)
    assert_includes monitor.reload.tags, tags(:production)
  end

  test "has_many status_pages through status_page_monitors" do
    monitor = site_monitors(:http_monitor)
    monitor.status_pages << status_pages(:service_status)
    assert_includes monitor.reload.status_pages, status_pages(:service_status)
  end

  # ── Enums ────────────────────────────────────────────────────────

  test "status enum values" do
    monitor = site_monitors(:http_monitor)

    monitor.status = "up"
    assert monitor.up?

    monitor.status = "down"
    assert monitor.down?

    monitor.status = "pending"
    assert_equal "pending", monitor.status

    monitor.status = "paused"
    assert_equal "paused", monitor.status
  end

  test "monitor_type enum values" do
    monitor = site_monitors(:http_monitor)

    %w[http keyword ping port heartbeat ssl domain dns api].each do |type|
      monitor.monitor_type = type
      assert_equal type, monitor.monitor_type
    end
  end

  test "defaults to pending status" do
    monitor = SiteMonitor.new(name: "Test", monitor_type: "http", interval: 60)
    assert_equal "pending", monitor.status
  end

  # ── Scopes ───────────────────────────────────────────────────────

  test "active scope returns non-paused monitors" do
    active_monitors = SiteMonitor.active
    assert_includes active_monitors, site_monitors(:http_monitor)
    assert_includes active_monitors, site_monitors(:ping_monitor)
    assert_not_includes active_monitors, site_monitors(:paused_monitor)
  end

  test "paused scope returns paused monitors" do
    paused_monitors = SiteMonitor.paused
    assert_includes paused_monitors, site_monitors(:paused_monitor)
    assert_not_includes paused_monitors, site_monitors(:http_monitor)
  end

  test "by_status scope filters by status" do
    up_monitors = SiteMonitor.by_status("up")
    assert_includes up_monitors, site_monitors(:http_monitor)
    assert_not_includes up_monitors, site_monitors(:paused_monitor)
  end

  test "by_type scope filters by monitor_type" do
    http_monitors = SiteMonitor.by_type("http")
    assert_includes http_monitors, site_monitors(:http_monitor)
    assert_includes http_monitors, site_monitors(:paused_monitor)
    assert_not_includes http_monitors, site_monitors(:ping_monitor)
  end

  # ── Instance Methods ─────────────────────────────────────────────

  test "up? returns true when status is up" do
    monitor = site_monitors(:http_monitor)
    assert monitor.up?
    assert_not monitor.down?
  end

  test "down? returns true when status is down" do
    monitor = site_monitors(:http_monitor)
    monitor.status = "down"
    assert monitor.down?
    assert_not monitor.up?
  end

  test "paused? returns true when paused column is true" do
    assert site_monitors(:paused_monitor).paused?
    assert_not site_monitors(:http_monitor).paused?
  end

  test "active? returns opposite of paused?" do
    assert site_monitors(:http_monitor).active?
    assert_not site_monitors(:paused_monitor).active?
  end
end
