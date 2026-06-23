class MonitorSchedulerJob < ApplicationJob
  queue_as :scheduler

  def perform
    now = Time.current

    SiteMonitor.active.find_each do |monitor|
      next if monitor.last_check_at.present? &&
              (now - monitor.last_check_at) < monitor.interval.seconds

      MonitorCheckJob.perform_later(monitor.id)
    end
  end
end
