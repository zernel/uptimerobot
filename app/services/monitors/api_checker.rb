module Monitors
  class ApiChecker < BaseChecker
    def check
      start_timer

      response = connection.send(http_method) do |req|
        req.url monitor.url
        req.headers.merge!(custom_headers)
        req.body = monitor.http_body if monitor.http_body.present?
      end

      json = JSON.parse(response.body)
      assertions_passed = evaluate_assertions(json)

      CheckResult.new(
        monitor: monitor,
        status: assertions_passed ? :up : :down,
        response_time: response_time,
        metadata: {
          http_status: response.status,
          assertions: monitor.api_assertions,
          assertions_passed: assertions_passed
        }
      )
    rescue JSON::ParserError => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: "Invalid JSON response: #{e.message}"
      )
    rescue Faraday::Error => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        error_message: e.message
      )
    end

    private

    def connection
      @connection ||= Faraday.new do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
        f.ssl.verify = monitor.verify_ssl?
      end
    end

    def http_method
      (monitor.http_method || 'get').downcase.to_sym
    end

    def custom_headers
      (monitor.http_headers || {}).transform_keys(&:to_s)
    end

    def evaluate_assertions(json)
      assertions = monitor.api_assertions || []

      assertions.all? do |assertion|
        actual = json_path(json, assertion['path'])
        compare(actual, assertion['operator'], assertion['value'])
      end
    end

    def json_path(json, path)
      parts = path.sub(/^\$\.?/, '').split('.')
      result = json

      parts.each do |part|
        if result.is_a?(Hash)
          result = result[part]
        else
          return nil
        end
      end

      result
    end

    def compare(actual, operator, expected)
      case operator
      when 'eq' then actual.to_s == expected.to_s
      when 'ne' then actual.to_s != expected.to_s
      when 'gt' then actual.to_f > expected.to_f
      when 'lt' then actual.to_f < expected.to_f
      when 'gte' then actual.to_f >= expected.to_f
      when 'lte' then actual.to_f <= expected.to_f
      when 'contains' then actual.to_s.include?(expected.to_s)
      when 'not_contains' then !actual.to_s.include?(expected.to_s)
      when 'exists' then !actual.nil?
      when 'not_exists' then actual.nil?
      else false
      end
    end
  end
end
