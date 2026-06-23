require "test_helper"

class NotificationDispatchJobTest < ActiveSupport::TestCase
  setup do
    @monitor = site_monitors(:http_monitor)
    @incident = incidents(:ongoing_incident)

    @slack_channel = NotificationChannel.create!(
      name: "Test Slack",
      channel_type: "slack",
      config: { "webhook_url" => "https://hooks.slack.com/test" },
      enabled: true
    )

    @email_channel = NotificationChannel.create!(
      name: "Test Email",
      channel_type: "email",
      config: { "address" => "test@example.com" },
      enabled: true
    )

    MonitorNotificationChannel.create!(monitor: @monitor, notification_channel: @slack_channel)
    MonitorNotificationChannel.create!(monitor: @monitor, notification_channel: @email_channel)

    stub_request(:post, "https://hooks.slack.com/test").to_return(status: 200, body: "ok")
  end

  test "dispatches to all configured channels" do
    assert_difference -> { NotificationLog.count }, 2 do
      NotificationDispatchJob.perform_now(@incident.id)
    end
  end

  test "creates notification log" do
    NotificationDispatchJob.perform_now(@incident.id)

    log = NotificationLog.last
    assert_equal @incident.id, log.incident_id
    assert_equal @monitor.id, log.monitor_id
    assert %w[sent failed].include?(log.status)
    assert log.sent_at.present?
  end
end
