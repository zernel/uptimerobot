class DashboardController < ApplicationController
  def index
    @monitors = Monitor.includes(:monitor_group, :tags).order(:name)
    @monitor_groups = MonitorGroup.includes(:monitors).order(:sort_order)
    @active_incidents = Incident.ongoing.includes(:monitor).order(started_at: :desc)
    @recent_incidents = Incident.resolved.includes(:monitor).order(resolved_at: :desc).limit(10)

    @stats = {
      total: Monitor.count,
      up: Monitor.up.count,
      down: Monitor.down.count,
      paused: Monitor.paused.count,
      pending: Monitor.pending.count
    }
  end
end
