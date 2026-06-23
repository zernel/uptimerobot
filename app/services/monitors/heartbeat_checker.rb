module Monitors
  class HeartbeatChecker < BaseChecker
    def check
      last_heartbeat = monitor.last_heartbeat_at

      if last_heartbeat.nil?
        return CheckResult.new(
          monitor: monitor,
          status: :down,
          error_message: 'No heartbeat received yet'
        )
      end

      time_since_last = Time.current - last_heartbeat
      expected_interval = monitor.heartbeat_interval.seconds
      grace_period = expected_interval * 0.1

      status = time_since_last <= (expected_interval + grace_period) ? :up : :down

      CheckResult.new(
        monitor: monitor,
        status: status,
        metadata: {
          last_heartbeat_at: last_heartbeat.iso8601,
          time_since_last: time_since_last.to_i,
          expected_interval: monitor.heartbeat_interval
        }
      )
    end
  end
end
