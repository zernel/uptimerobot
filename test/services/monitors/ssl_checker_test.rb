require "test_helper"

class Monitors::SslCheckerTest < ActiveSupport::TestCase
  setup do
    @monitor = site_monitors(:http_monitor)
    @monitor.update!(hostname: "example.com")
  end

  test "returns up status for valid certificate" do
    cert = OpenSSL::X509::Certificate.new
    cert.subject = OpenSSL::X509::Name.new([["CN", "example.com"]])
    cert.issuer = OpenSSL::X509::Name.new([["CN", "Test CA"]])
    cert.not_before = 30.days.ago
    cert.not_after = 30.days.from_now
    cert.serial = 12345

    ssl_socket = Object.new
    ssl_socket.define_singleton_method(:connect) { true }
    ssl_socket.define_singleton_method(:peer_cert) { cert }
    ssl_socket.define_singleton_method(:close) { nil }

    tcp_socket = Object.new
    tcp_socket.define_singleton_method(:close) { nil }

    original_tcp_new = TCPSocket.method(:new)
    original_ssl_new = OpenSSL::SSL::SSLSocket.method(:new)
    TCPSocket.define_singleton_method(:new) { |*args| tcp_socket }
    OpenSSL::SSL::SSLSocket.define_singleton_method(:new) { |*args| ssl_socket }

    begin
      checker = Monitors::SslChecker.new(@monitor)
      result = checker.check

      assert_equal "up", result.status
      assert_equal @monitor, result.monitor
      assert result.metadata["days_until_expiry"] > 0
      assert_equal "example.com", result.metadata["subject"].split("=").last
    ensure
      TCPSocket.define_singleton_method(:new, original_tcp_new)
      OpenSSL::SSL::SSLSocket.define_singleton_method(:new, original_ssl_new)
    end
  end

  test "returns down status when certificate cannot be fetched" do
    original_tcp_new = TCPSocket.method(:new)
    TCPSocket.define_singleton_method(:new) { |*args| raise Errno::ECONNREFUSED, "Connection refused" }

    begin
      checker = Monitors::SslChecker.new(@monitor)
      result = checker.check

      assert_equal "down", result.status
      assert_equal "Unable to fetch SSL certificate", result.error_message
    ensure
      TCPSocket.define_singleton_method(:new, original_tcp_new)
    end
  end
end
