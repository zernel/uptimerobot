module Monitors
  class PortChecker < BaseChecker
    def check
      start_timer

      socket = TCPSocket.new(
        monitor.hostname,
        monitor.port,
        nil, nil,
        connect_timeout: monitor.timeout
      )

      response_time = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).to_i
      socket.close

      CheckResult.new(
        monitor: monitor,
        status: :up,
        response_time: response_time,
        metadata: {
          host: monitor.hostname,
          port: monitor.port
        }
      )
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Errno::EHOSTUNREACH, SocketError => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: e.message,
        metadata: {
          error_class: e.class.name,
          host: monitor.hostname,
          port: monitor.port
        }
      )
    end
  end
end
