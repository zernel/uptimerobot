require "test_helper"

class MonitorSchedulerJobTest < ActiveSupport::TestCase
  test "enqueues MonitorCheckJob for monitors due for check" do
    SiteMonitor.active.update_all(last_check_at: 10.seconds.ago)
    monitor = site_monitors(:http_monitor)
    monitor.update!(last_check_at: 2.minutes.ago, interval: 60)

    assert_enqueued_with(job: MonitorCheckJob, args: [monitor.id]) do
      MonitorSchedulerJob.perform_now
    end
  end

  test "skips monitors checked recently" do
    SiteMonitor.active.update_all(last_check_at: 10.seconds.ago, interval: 300)

    assert_no_enqueued_jobs do
      MonitorSchedulerJob.perform_now
    end
  end

  test "skips paused monitors" do
    SiteMonitor.where(paused: false).update_all(last_check_at: 10.seconds.ago, interval: 300)

    assert_no_enqueued_jobs do
      MonitorSchedulerJob.perform_now
    end
  end
end
