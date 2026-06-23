module Notifiers
  class EmailNotifier < BaseNotifier
    def notify
      MonitorMailer.alert(
        to: channel.config['address'],
        incident: incident,
        message: message
      ).deliver_later

      { success: true }
    rescue => e
      { success: false, error: e.message }
    end
  end
end
