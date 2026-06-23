class NotificationDispatchJob < ApplicationJob
  queue_as :notifications

  def perform(incident_id)
    incident = Incident.find(incident_id)
    monitor = incident.monitor

    monitor.notification_channels.enabled.find_each do |channel|
      result = send_notification(channel, incident)
      log_notification(channel, incident, result)
    end
  end

  private

  def send_notification(channel, incident)
    notifier = notifier_for(channel, incident)
    notifier.notify
  end

  def notifier_for(channel, incident)
    case channel.channel_type
    when 'email' then Notifiers::EmailNotifier.new(channel, incident)
    when 'slack', 'mattermost', 'feishu' then Notifiers::WebhookNotifier.new(channel, incident)
    else raise "Unknown channel type: #{channel.channel_type}"
    end
  end

  def log_notification(channel, incident, result)
    NotificationLog.create!(
      incident: incident,
      notification_channel: channel,
      monitor: incident.monitor,
      status: result[:success] ? 'sent' : 'failed',
      message: message_for(incident),
      error_message: result[:error],
      sent_at: Time.current
    )

    channel.update!(
      last_used_at: Time.current,
      last_error: result[:success] ? nil : result[:error]
    )
  end

  def message_for(incident)
    notifier = Notifiers::BaseNotifier.new(nil, incident)
    notifier.send(:message)
  end
end
