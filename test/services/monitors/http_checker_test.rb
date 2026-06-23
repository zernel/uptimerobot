require "test_helper"

class Monitors::HttpCheckerTest < ActiveSupport::TestCase
  setup do
    @monitor = site_monitors(:http_monitor)
  end

  test "returns up status for 200 response" do
    stub_request(:get, "https://example.com").to_return(status: 200, body: "OK")

    checker = Monitors::HttpChecker.new(@monitor)
    result = checker.check

    assert_equal "up", result.status
    assert_equal @monitor, result.monitor
    assert result.response_time.present?
    assert_equal 200, result.metadata["http_status"]
  end

  test "returns down status for non-200 response" do
    stub_request(:get, "https://example.com").to_return(status: 500, body: "Internal Server Error")

    checker = Monitors::HttpChecker.new(@monitor)
    result = checker.check

    assert_equal "down", result.status
    assert_equal 500, result.metadata["http_status"]
  end

  test "handles connection errors" do
    stub_request(:get, "https://example.com").to_raise(Faraday::ConnectionFailed.new("Connection refused"))

    checker = Monitors::HttpChecker.new(@monitor)
    result = checker.check

    assert_equal "down", result.status
    assert result.error_message.present?
    assert_equal "Faraday::ConnectionFailed", result.metadata["error_class"]
  end

  test "handles timeout errors" do
    stub_request(:get, "https://example.com").to_timeout

    checker = Monitors::HttpChecker.new(@monitor)
    result = checker.check

    assert_equal "down", result.status
    assert result.error_message.present?
  end

  test "sends custom headers" do
    @monitor.update!(http_headers: { "Authorization" => "Bearer token123", "X-Custom" => "value" })

    stub_request(:get, "https://example.com")
      .with(headers: { "Authorization" => "Bearer token123", "X-Custom" => "value" })
      .to_return(status: 200, body: "OK")

    checker = Monitors::HttpChecker.new(@monitor)
    result = checker.check

    assert_equal "up", result.status
  end

  test "uses correct HTTP GET method" do
    @monitor.update!(http_method: "GET")

    stub_request(:get, "https://example.com").to_return(status: 200, body: "OK")

    checker = Monitors::HttpChecker.new(@monitor)
    result = checker.check

    assert_equal "up", result.status
  end

  test "uses correct HTTP POST method" do
    @monitor.update!(http_method: "POST", http_body: '{"key":"value"}')

    stub_request(:post, "https://example.com")
      .with(body: '{"key":"value"}')
      .to_return(status: 200, body: "OK")

    checker = Monitors::HttpChecker.new(@monitor)
    result = checker.check

    assert_equal "up", result.status
  end

  test "measures response time" do
    stub_request(:get, "https://example.com").to_return(status: 200, body: "OK")

    checker = Monitors::HttpChecker.new(@monitor)
    result = checker.check

    assert result.response_time.is_a?(Integer)
    assert result.response_time >= 0
  end
end
