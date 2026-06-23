module Monitors
  class KeywordChecker < BaseChecker
    def check
      start_timer

      response = connection.get(monitor.url)
      body = response.body.to_s
      keyword_found = body.include?(monitor.keyword)

      status = case monitor.keyword_type
               when 'exists'
                 keyword_found ? :up : :down
               when 'not_exists'
                 keyword_found ? :down : :up
               else
                 :down
               end

      CheckResult.new(
        monitor: monitor,
        status: status,
        response_time: response_time,
        metadata: {
          http_status: response.status,
          keyword_found: keyword_found,
          keyword: monitor.keyword
        }
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
  end
end
