require "test_helper"

class MaintenanceWindowTest < ActiveSupport::TestCase
  # ── Validations ──────────────────────────────────────────────────

  test "requires name" do
    window = MaintenanceWindow.new(starts_at: 1.hour.from_now, ends_at: 2.hours.from_now)
    assert_not window.valid?
    assert_includes window.errors[:name], "can't be blank"
  end

  test "requires starts_at" do
    window = MaintenanceWindow.new(name: "Maintenance", ends_at: 2.hours.from_now)
    assert_not window.valid?
    assert_includes window.errors[:starts_at], "can't be blank"
  end

  test "requires ends_at" do
    window = MaintenanceWindow.new(name: "Maintenance", starts_at: 1.hour.from_now)
    assert_not window.valid?
    assert_includes window.errors[:ends_at], "can't be blank"
  end

  test "ends_at must be after starts_at" do
    now = Time.current
    window = MaintenanceWindow.new(name: "Maintenance", starts_at: now, ends_at: now)
    assert_not window.valid?
    assert_includes window.errors[:ends_at], "must be after starts_at"
  end

  test "ends_at must be after starts_at not before" do
    now = Time.current
    window = MaintenanceWindow.new(name: "Maintenance", starts_at: now, ends_at: 1.hour.ago)
    assert_not window.valid?
    assert_includes window.errors[:ends_at], "must be after starts_at"
  end

  test "valid with ends_at after starts_at" do
    window = MaintenanceWindow.new(
      name: "Scheduled Maintenance",
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now
    )
    assert window.valid?
  end

  # ── Scopes ───────────────────────────────────────────────────────

  test "active scope returns windows covering current time" do
    window = MaintenanceWindow.create!(
      name: "Active Window",
      starts_at: 1.hour.ago,
      ends_at: 1.hour.from_now
    )
    assert_includes MaintenanceWindow.active, window
  end

  test "active scope excludes windows not covering current time" do
    window = MaintenanceWindow.create!(
      name: "Future Window",
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now
    )
    assert_not_includes MaintenanceWindow.active, window
  end

  test "upcoming scope returns future windows" do
    window = MaintenanceWindow.create!(
      name: "Upcoming Window",
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now
    )
    assert_includes MaintenanceWindow.upcoming, window
  end

  test "upcoming scope excludes past windows" do
    window = MaintenanceWindow.create!(
      name: "Past Window",
      starts_at: 2.hours.ago,
      ends_at: 1.hour.ago
    )
    assert_not_includes MaintenanceWindow.upcoming, window
  end

  # ── Instance Methods ─────────────────────────────────────────────

  test "active? returns true when current time is within window" do
    window = MaintenanceWindow.new(
      name: "Active Window",
      starts_at: 1.hour.ago,
      ends_at: 1.hour.from_now
    )
    assert window.active?
  end

  test "active? returns false when current time is outside window" do
    window = MaintenanceWindow.new(
      name: "Future Window",
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now
    )
    assert_not window.active?
  end

  test "upcoming? returns true when starts_at is in the future" do
    window = MaintenanceWindow.new(
      name: "Future Window",
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now
    )
    assert window.upcoming?
  end

  test "upcoming? returns false when starts_at is in the past" do
    window = MaintenanceWindow.new(
      name: "Past Window",
      starts_at: 1.hour.ago,
      ends_at: 1.hour.from_now
    )
    assert_not window.upcoming?
  end
end
