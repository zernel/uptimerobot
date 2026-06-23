require "test_helper"

class MonitorCheckJobTest < ActiveSupport::TestCase
  setup do
    @monitor = site_monitors(:http_monitor)
  end

  test "skips paused monitors" do
    paused = site_monitors(:paused_monitor)

    assert_no_difference -> { CheckResult.count } do
      MonitorCheckJob.perform_now(paused.id)
    end
  end

  test "creates check result" do
    stub_request(:get, "https://example.com").to_return(status: 200, body: "OK")

    assert_difference -> { CheckResult.count }, 1 do
      MonitorCheckJob.perform_now(@monitor.id)
    end

    result = CheckResult.last
    assert_equal @monitor.id, result.monitor_id
    assert_equal "up", result.status
  end

  test "updates monitor status" do
    @monitor.update!(status: "pending")
    stub_request(:get, "https://example.com").to_return(status: 200, body: "OK")

    MonitorCheckJob.perform_now(@monitor.id)

    @monitor.reload
    assert_equal "up", @monitor.status
    assert @monitor.last_check_at.present?
  end

  test "creates incident on status change to down" do
    @monitor.update!(status: "up")
    stub_request(:get, "https://example.com").to_return(status: 500, body: "Error")

    assert_difference -> { Incident.count }, 1 do
      MonitorCheckJob.perform_now(@monitor.id)
    end

    incident = Incident.last
    assert_equal @monitor.id, incident.monitor_id
    assert_equal "ongoing", incident.status
    assert incident.started_at.present?
  end

  test "enqueues notification on status change" do
    @monitor.update!(status: "up")
    stub_request(:get, "https://example.com").to_return(status: 500, body: "Error")

    assert_enqueued_with(job: NotificationDispatchJob) do
      MonitorCheckJob.perform_now(@monitor.id)
    end
  end
end
