module Monitors
  class PingChecker < BaseChecker
    def check
      start_timer

      ping = Net::Ping::ICMP.new(monitor.hostname, nil, monitor.timeout)
      ping.ping

      CheckResult.new(
        monitor: monitor,
        status: ping.status == 'alive' ? :up : :down,
        response_time: (ping.duration * 1000).to_i,
        checked_at: Time.current,
        metadata: {
          ping_duration: ping.duration,
          host: monitor.hostname
        }
      )
    rescue => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        checked_at: Time.current,
        error_message: e.message
      )
    end
  end
end
