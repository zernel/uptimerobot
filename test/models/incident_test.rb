require "test_helper"

class IncidentTest < ActiveSupport::TestCase
  # ── Validations ──────────────────────────────────────────────────

  test "requires started_at" do
    incident = Incident.new(monitor: site_monitors(:http_monitor))
    assert_not incident.valid?
    assert_includes incident.errors[:started_at], "can't be blank"
  end

  test "defaults to ongoing status" do
    incident = Incident.new(
      monitor: site_monitors(:http_monitor),
      started_at: Time.current
    )
    assert_equal "ongoing", incident.status
  end

  test "valid incident with required attributes" do
    incident = Incident.new(
      monitor: site_monitors(:http_monitor),
      started_at: 1.hour.ago,
      status: "ongoing"
    )
    assert incident.valid?
  end

  # ── Associations ─────────────────────────────────────────────────

  test "belongs_to monitor" do
    incident = incidents(:ongoing_incident)
    assert_equal site_monitors(:http_monitor), incident.monitor
  end

  # ── Scopes ───────────────────────────────────────────────────────

  test "ongoing scope returns ongoing incidents" do
    ongoing = Incident.ongoing
    assert_includes ongoing, incidents(:ongoing_incident)
    assert_not_includes ongoing, incidents(:resolved_incident)
  end

  test "resolved scope returns resolved incidents" do
    resolved = Incident.resolved
    assert_includes resolved, incidents(:resolved_incident)
    assert_not_includes resolved, incidents(:ongoing_incident)
  end

  test "recent scope orders by started_at descending" do
    recent = Incident.recent
    assert_equal incidents(:ongoing_incident), recent.first
    assert_equal incidents(:resolved_incident), recent.second
  end

  # ── Instance Methods ─────────────────────────────────────────────

  test "resolve! sets status to resolved and resolved_at" do
    incident = incidents(:ongoing_incident)
    freeze_time do
      incident.resolve!
      assert_equal "resolved", incident.status
      assert_equal Time.current, incident.resolved_at
    end
  end

  test "duration_seconds for resolved incident" do
    incident = incidents(:resolved_incident)
    expected = (incident.resolved_at - incident.started_at).to_i
    assert_equal expected, incident.duration_seconds
  end

  test "duration_seconds for ongoing incident uses current time" do
    incident = incidents(:ongoing_incident)
    freeze_time do
      expected = (Time.current - incident.started_at).to_i
      assert_equal expected, incident.duration_seconds
    end
  end
end
