require "test_helper"

class DataCleanupJobTest < ActiveSupport::TestCase
  test "deletes old check results" do
    monitor = site_monitors(:http_monitor)

    old_result = CheckResult.create!(
      monitor: monitor,
      status: "up",
      checked_at: 10.days.ago,
      response_time: 100
    )

    recent_result = CheckResult.create!(
      monitor: monitor,
      status: "up",
      checked_at: 1.day.ago,
      response_time: 100
    )

    DataCleanupJob.perform_now

    assert_raises(ActiveRecord::RecordNotFound) { old_result.reload }
    assert_nothing_raised { recent_result.reload }
  end

  test "deletes old notification logs" do
    monitor = site_monitors(:http_monitor)
    incident = incidents(:ongoing_incident)
    channel = notification_channels(:slack_channel)

    old_log = NotificationLog.create!(
      monitor: monitor,
      incident: incident,
      notification_channel: channel,
      status: "sent",
      sent_at: 100.days.ago,
      created_at: 100.days.ago
    )

    recent_log = NotificationLog.create!(
      monitor: monitor,
      incident: incident,
      notification_channel: channel,
      status: "sent",
      sent_at: 1.day.ago
    )

    DataCleanupJob.perform_now

    assert_raises(ActiveRecord::RecordNotFound) { old_log.reload }
    assert_nothing_raised { recent_log.reload }
  end
end
