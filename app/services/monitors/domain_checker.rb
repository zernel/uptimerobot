module Monitors
  class DomainChecker < BaseChecker
    def check
      whois = Whois.whois(monitor.hostname)
      parser = Whois::Parser.new(whois)

      expiry_date = parser.expires_on

      if expiry_date.nil?
        return CheckResult.new(
          monitor: monitor,
          status: :down,
          error_message: 'Unable to determine domain expiry date'
        )
      end

      days_until_expiry = (expiry_date - Time.current).to_i / 1.day
      status = days_until_expiry > 0 ? :up : :down

      CheckResult.new(
        monitor: monitor,
        status: status,
        metadata: {
          registrar: parser.registrar&.name,
          created_on: parser.created_on&.iso8601,
          updated_on: parser.updated_on&.iso8601,
          expires_on: expiry_date.iso8601,
          days_until_expiry: days_until_expiry
        }
      )
    rescue => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: e.message
      )
    end
  end
end
