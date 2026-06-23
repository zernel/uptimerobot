module Monitors
  class BaseChecker
    attr_reader :monitor, :start_time

    def initialize(monitor)
      @monitor = monitor
    end

    def check
      raise NotImplementedError, "#{self.class} must implement #check"
    end

    private

    def response_time
      return nil unless start_time
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).to_i
    end

    def start_timer
      @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
