class DashboardController < ApplicationController
  def index
    @monitors = SiteMonitor.includes(:monitor_group, :tags).order(:name)
    @monitor_groups = MonitorGroup.includes(:monitors).order(:sort_order)
    @active_incidents = Incident.ongoing.includes(:monitor).order(started_at: :desc)
    @recent_incidents = Incident.resolved.includes(:monitor).order(resolved_at: :desc).limit(10)

    @stats = {
      total: SiteMonitor.count,
      up: SiteMonitor.up.count,
      down: SiteMonitor.down.count,
      paused: SiteMonitor.paused.count,
      pending: SiteMonitor.pending.count
    }
  end
end
