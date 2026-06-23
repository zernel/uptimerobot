module Notifiers
  class BaseNotifier
    attr_reader :channel, :incident

    def initialize(channel, incident)
      @channel = channel
      @incident = incident
    end

    def notify
      raise NotImplementedError
    end

    private

    def monitor
      incident.monitor
    end

    def message
      if incident.ongoing?
        down_message
      else
        up_message
      end
    end

    def down_message
      "Monitor Down: #{monitor.name}\nURL: #{monitor.url || monitor.hostname}\nStatus: Down\nStarted: #{incident.started_at.strftime('%Y-%m-%d %H:%M:%S UTC')}\nCause: #{incident.cause_detail || incident.cause}"
    end

    def up_message
      "Monitor Up: #{monitor.name}\nURL: #{monitor.url || monitor.hostname}\nStatus: Up\nDowntime: #{distance_of_time_in_words(incident.duration)}\nIncident resolved at #{incident.resolved_at.strftime('%Y-%m-%d %H:%M:%S UTC')}"
    end
  end
end
