module Monitors
  class HttpChecker < BaseChecker
    def check
      start_timer

      response = connection.send(http_method) do |req|
        req.url monitor.url
        req.headers.merge!(custom_headers)
        req.body = monitor.http_body if monitor.http_body.present?
        req.options.timeout = monitor.timeout
        req.options.open_timeout = 10
      end

      CheckResult.new(
        monitor: monitor,
        status: determine_status(response),
        response_time: response_time,
        checked_at: Time.current,
        metadata: {
          http_status: response.status,
          response_size: response.body&.length,
          redirect_count: response.env.url.to_s != monitor.url ? 1 : 0
        }
      )
    rescue Faraday::Error => e
      CheckResult.new(
        monitor: monitor,
        status: :down,
        checked_at: Time.current,
        error_message: e.message,
        metadata: { error_class: e.class.name }
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

    def determine_status(response)
      success_codes = [200]
      success_codes.include?(response.status) ? :up : :down
    end
  end
end
