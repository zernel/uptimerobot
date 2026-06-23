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

    TCPSocket.stub(:new, tcp_socket) do
      OpenSSL::SSL::SSLSocket.stub(:new, ssl_socket) do
        checker = Monitors::SslChecker.new(@monitor)
        result = checker.check

        assert_equal "up", result.status
        assert_equal @monitor, result.monitor
        assert result.metadata["days_until_expiry"] > 0
        assert_equal "example.com", result.metadata["subject"].split("=").last
      end
    end
  end

  test "returns down status when certificate cannot be fetched" do
    TCPSocket.stub(:new, ->(*_args) { raise Errno::ECONNREFUSED, "Connection refused" }) do
      checker = Monitors::SslChecker.new(@monitor)
      result = checker.check

      assert_equal "down", result.status
      assert_equal "Unable to fetch SSL certificate", result.error_message
    end
  end
end
