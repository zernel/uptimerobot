require "test_helper"

module Net
  module Ping
    class ICMP
      def initialize(host, port = nil, timeout = nil); end
      def ping; end
      def status; end
      def duration; end
    end
  end
end

class Monitors::PingCheckerTest < ActiveSupport::TestCase
  setup do
    @monitor = site_monitors(:ping_monitor)
  end

  test "returns up status when host is alive" do
    ping_obj = Object.new
    ping_obj.define_singleton_method(:ping) { true }
    ping_obj.define_singleton_method(:status) { "alive" }
    ping_obj.define_singleton_method(:duration) { 0.005 }

    original_new = Net::Ping::ICMP.method(:new)
    Net::Ping::ICMP.define_singleton_method(:new) { |*args| ping_obj }

    begin
      checker = Monitors::PingChecker.new(@monitor)
      result = checker.check

      assert_equal "up", result.status
      assert_equal @monitor, result.monitor
      assert_equal 5, result.response_time
      assert_equal 0.005, result.metadata["ping_duration"]
      assert_equal "8.8.8.8", result.metadata["host"]
    ensure
      Net::Ping::ICMP.define_singleton_method(:new, original_new)
    end
  end

  test "returns down status when host is unreachable" do
    ping_obj = Object.new
    ping_obj.define_singleton_method(:ping) { false }
    ping_obj.define_singleton_method(:status) { "timeout" }

    original_new = Net::Ping::ICMP.method(:new)
    Net::Ping::ICMP.define_singleton_method(:new) { |*args| ping_obj }

    begin
      checker = Monitors::PingChecker.new(@monitor)
      result = checker.check

      assert_equal "down", result.status
      assert_equal @monitor, result.monitor
    ensure
      Net::Ping::ICMP.define_singleton_method(:new, original_new)
    end
  end
end
