require "test_helper"

class MonitorGroupTest < ActiveSupport::TestCase
  # ── Validations ──────────────────────────────────────────────────

  test "requires name" do
    group = MonitorGroup.new
    assert_not group.valid?
    assert_includes group.errors[:name], "can't be blank"
  end

  test "valid with name" do
    group = MonitorGroup.new(name: "Test Group")
    assert group.valid?
  end

  # ── Associations ─────────────────────────────────────────────────

  test "has_many monitors" do
    group = monitor_groups(:web_group)
    group.monitors << site_monitors(:http_monitor)
    assert_includes group.reload.monitors, site_monitors(:http_monitor)
  end

  test "destroying group nullifies monitor group_id" do
    group = monitor_groups(:web_group)
    group.monitors << site_monitors(:http_monitor)
    monitor_id = site_monitors(:http_monitor).id

    group.destroy
    assert_nil SiteMonitor.find(monitor_id).monitor_group_id
  end
end
