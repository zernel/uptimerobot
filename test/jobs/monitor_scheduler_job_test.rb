require "test_helper"

class MonitorSchedulerJobTest < ActiveSupport::TestCase
  test "enqueues MonitorCheckJob for monitors due for check" do
    monitor = site_monitors(:http_monitor)
    monitor.update!(last_check_at: 2.minutes.ago, interval: 60)

    assert_enqueued_with(job: MonitorCheckJob, args: [monitor.id]) do
      MonitorSchedulerJob.perform_now
    end
  end

  test "skips monitors checked recently" do
    monitor = site_monitors(:http_monitor)
    monitor.update!(last_check_at: 10.seconds.ago, interval: 60)

    assert_no_enqueued_jobs(only: MonitorCheckJob) do
      MonitorSchedulerJob.perform_now
    end
  end

  test "skips paused monitors" do
    monitor = site_monitors(:paused_monitor)
    monitor.update!(last_check_at: 2.minutes.ago)

    assert_no_enqueued_jobs(only: MonitorCheckJob) do
      MonitorSchedulerJob.perform_now
    end
  end
end
