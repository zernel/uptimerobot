require "test_helper"

class CheckResultTest < ActiveSupport::TestCase
  # ── Validations ──────────────────────────────────────────────────

  test "requires status" do
    result = CheckResult.new(monitor: site_monitors(:http_monitor), checked_at: Time.current)
    assert_not result.valid?
    assert_includes result.errors[:status], "can't be blank"
  end

  test "requires checked_at" do
    result = CheckResult.new(monitor: site_monitors(:http_monitor), status: "up")
    assert_not result.valid?
    assert_includes result.errors[:checked_at], "can't be blank"
  end

  test "valid with required attributes" do
    result = CheckResult.new(
      monitor: site_monitors(:http_monitor),
      status: "up",
      checked_at: Time.current
    )
    assert result.valid?
  end

  # ── Associations ─────────────────────────────────────────────────

  test "belongs_to monitor" do
    result = check_results(:recent_success)
    assert_equal site_monitors(:http_monitor), result.monitor
  end

  # ── Scopes ───────────────────────────────────────────────────────

  test "recent scope orders by checked_at descending" do
    recent = CheckResult.recent
    assert_equal check_results(:recent_success), recent.first
    assert_equal check_results(:recent_failure), recent.second
  end

  test "up scope returns only up results" do
    up_results = CheckResult.up
    assert_includes up_results, check_results(:recent_success)
    assert_not_includes up_results, check_results(:recent_failure)
  end

  test "down scope returns only down results" do
    down_results = CheckResult.down
    assert_includes down_results, check_results(:recent_failure)
    assert_not_includes down_results, check_results(:recent_success)
  end

  # ── Enum ─────────────────────────────────────────────────────────

  test "status enum supports up and down" do
    result = check_results(:recent_success)
    assert_equal "up", result.status

    result.status = "down"
    assert_equal "down", result.status
  end
end
