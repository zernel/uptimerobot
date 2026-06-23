class MonitorMailer < ApplicationMailer
  def alert(to:, incident:, message:)
    @incident = incident
    @monitor = incident.monitor
    @message = message

    mail(
      to: to,
      subject: "Monitor #{@incident.ongoing? ? 'Down' : 'Up'}: #{@monitor.name}"
    )
  end
end
