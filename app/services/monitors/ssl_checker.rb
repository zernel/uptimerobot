module Monitors
  class SslChecker < BaseChecker
    def check
      certificate = fetch_certificate

      if certificate.nil?
        return CheckResult.new(
          monitor: monitor,
          status: :down,
          error_message: 'Unable to fetch SSL certificate'
        )
      end

      days_until_expiry = (certificate.not_after - Time.current).to_i / 1.day
      status = days_until_expiry > 0 ? :up : :down

      CheckResult.new(
        monitor: monitor,
        status: status,
        metadata: {
          subject: certificate.subject.to_s,
          issuer: certificate.issuer.to_s,
          not_before: certificate.not_before.iso8601,
          not_after: certificate.not_after.iso8601,
          days_until_expiry: days_until_expiry,
          serial: certificate.serial.to_s
        }
      )
    rescue => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: e.message
      )
    end

    private

    def fetch_certificate
      uri = URI.parse("https://#{monitor.hostname}")

      tcp = TCPSocket.new(uri.host, uri.port || 443)
      ssl = OpenSSL::SSL::SSLSocket.new(tcp)
      ssl.connect

      cert = ssl.peer_cert
      ssl.close
      tcp.close

      cert
    rescue => e
      nil
    end
  end
end
