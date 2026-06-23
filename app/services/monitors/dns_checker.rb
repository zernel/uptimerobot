module Monitors
  class DnsChecker < BaseChecker
    def check
      resolver = Resolv::DNS.new
      records = resolver.getresources(
        monitor.hostname,
        record_class
      )

      values = records.map(&:value).map(&:to_s)
      expected = monitor.dns_expected_value

      status = if expected.present?
                 values.include?(expected) ? :up : :down
               else
                 values.any? ? :up : :down
               end

      CheckResult.new(
        monitor: monitor,
        status: status,
        metadata: {
          record_type: monitor.dns_record_type,
          values: values,
          expected_value: expected
        }
      )
    rescue Resolv::ResolvError => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: e.message
      )
    end

    private

    def record_class
      case monitor.dns_record_type
      when 'A' then Resolv::DNS::Resource::IN::A
      when 'AAAA' then Resolv::DNS::Resource::IN::AAAA
      when 'CNAME' then Resolv::DNS::Resource::IN::CNAME
      when 'MX' then Resolv::DNS::Resource::IN::MX
      when 'TXT' then Resolv::DNS::Resource::IN::TXT
      else Resolv::DNS::Resource::IN::A
      end
    end
  end
end
