class MonitorCheckJob < ApplicationJob
  queue_as :monitors

  if respond_to?(:good_job_control_concurrency_with)
    good_job_control_concurrency_with(
      total_limit: 10,
      key: -> { "monitor-check-#{arguments.first}" }
    )
  end

  def perform(monitor_id)
    monitor = SiteMonitor.find(monitor_id)
    return if monitor.paused?

    checker = checker_for(monitor)
    result = checker.check

    ActiveRecord::Base.transaction do
      result.save!
      update_monitor_status(monitor, result)
      create_incident_if_needed(monitor, result)
      notify_if_needed(monitor, result)
    end
  end

  private

  def checker_for(monitor)
    case monitor.monitor_type
    when 'http', 'https' then Monitors::HttpChecker.new(monitor)
    when 'keyword' then Monitors::KeywordChecker.new(monitor)
    when 'ping' then Monitors::PingChecker.new(monitor)
    when 'port' then Monitors::PortChecker.new(monitor)
    when 'heartbeat' then Monitors::HeartbeatChecker.new(monitor)
    when 'ssl' then Monitors::SslChecker.new(monitor)
    when 'domain' then Monitors::DomainChecker.new(monitor)
    when 'dns' then Monitors::DnsChecker.new(monitor)
    when 'api' then Monitors::ApiChecker.new(monitor)
    else raise "Unknown monitor type: #{monitor.monitor_type}"
    end
  end

  def update_monitor_status(monitor, result)
    old_status = monitor.status
    new_status = result.status

    if old_status == new_status
      monitor.update!(
        consecutive_failures: new_status == 'down' ? monitor.consecutive_failures + 1 : 0,
        last_check_at: Time.current,
        response_time: result.response_time
      )
    else
      monitor.update!(
        status: new_status,
        consecutive_failures: new_status == 'down' ? 1 : 0,
        last_check_at: Time.current,
        last_status_change_at: Time.current,
        response_time: result.response_time
      )
    end
  end

  def create_incident_if_needed(monitor, result)
    return unless monitor.saved_change_to_status?

    if result.down?
      monitor.incidents.create!(
        status: :ongoing,
        started_at: Time.current,
        cause: result.metadata&.dig('error_class') || 'check_failed',
        cause_detail: result.error_message
      )
    elsif result.up?
      incident = monitor.incidents.ongoing.last
      if incident
        incident.update!(
          status: :resolved,
          resolved_at: Time.current,
          duration: (Time.current - incident.started_at).to_i
        )
      end
    end
  end

  def notify_if_needed(monitor, result)
    return unless monitor.saved_change_to_status?
    return unless should_notify?(monitor, result)

    incident = monitor.incidents.last
    NotificationDispatchJob.perform_later(incident.id)
  end

  def should_notify?(monitor, result)
    return false if MaintenanceWindow.active.exists?

    if monitor.alert_delay > 0 && result.down?
      return false if monitor.last_status_change_at.nil?
      return false if Time.current - monitor.last_status_change_at < monitor.alert_delay.seconds
    end

    if result.down?
      return monitor.consecutive_failures >= monitor.alert_threshold
    end

    true
  end
end
