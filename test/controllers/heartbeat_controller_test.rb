require "test_helper"

class HeartbeatControllerTest < ActionDispatch::IntegrationTest
  # ── No Authentication Required ──────────────────────────────────

  test "does not require authentication" do
    get heartbeat_url(site_monitors(:heartbeat_monitor).heartbeat_token)
    assert_response :success
  end

  # ── Ping ───────────────────────────────────────────────────────

  test "ping returns ok for valid token" do
    get heartbeat_url(site_monitors(:heartbeat_monitor).heartbeat_token)
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
  end

  test "ping updates last_heartbeat_at" do
    monitor = site_monitors(:heartbeat_monitor)
    freeze_time do
      get heartbeat_url(monitor.heartbeat_token)
      assert_response :success
      assert_equal Time.current.to_i, monitor.reload.last_heartbeat_at.to_i
    end
  end

  # ── Invalid Token ──────────────────────────────────────────────

  test "returns 404 for invalid token" do
    get heartbeat_url("nonexistent-token-999")
    assert_response :not_found
    json = JSON.parse(response.body)
    assert_equal "Not found", json["error"]
  end
end
