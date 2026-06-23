require "test_helper"

class MonitorsControllerTest < ActionDispatch::IntegrationTest
  # ── Authentication ──────────────────────────────────────────────

  test "requires authentication for index" do
    get monitors_url
    assert_redirected_to new_user_session_url
  end

  test "requires authentication for show" do
    get monitor_url(site_monitors(:http_monitor))
    assert_redirected_to new_user_session_url
  end

  # ── Index ──────────────────────────────────────────────────────

  test "index lists monitors" do
    sign_in users(:admin)
    get monitors_url
    assert_response :success
  end

  test "index filters by status" do
    sign_in users(:admin)
    get monitors_url, params: { status: "up" }
    assert_response :success
  end

  test "index filters by monitor type" do
    sign_in users(:admin)
    get monitors_url, params: { type: "http" }
    assert_response :success
  end

  test "index filters by group" do
    sign_in users(:admin)
    get monitors_url, params: { group_id: monitor_groups(:web_group).id }
    assert_response :success
  end

  # ── Show ───────────────────────────────────────────────────────

  test "show displays monitor details" do
    sign_in users(:admin)
    get monitor_url(site_monitors(:http_monitor))
    assert_response :success
  end

  # ── Create ─────────────────────────────────────────────────────

  test "new renders form" do
    sign_in users(:admin)
    get new_monitor_url
    assert_response :success
  end

  test "create with valid params" do
    sign_in users(:admin)
    assert_difference("SiteMonitor.count", 1) do
      post monitors_url, params: {
        monitor: {
          name: "New Test Monitor",
          monitor_type: "http",
          url: "https://new.example.com",
          interval: 60,
          timeout: 30
        }
      }
    end
    assert_redirected_to monitor_url(SiteMonitor.order(:created_at).last)
  end

  test "create with invalid params" do
    sign_in users(:admin)
    assert_no_difference("SiteMonitor.count") do
      post monitors_url, params: {
        monitor: {
          name: "",
          monitor_type: "http",
          interval: 60
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # ── Update ─────────────────────────────────────────────────────

  test "edit renders form" do
    sign_in users(:admin)
    get edit_monitor_url(site_monitors(:http_monitor))
    assert_response :success
  end

  test "update with valid params" do
    sign_in users(:admin)
    patch monitor_url(site_monitors(:http_monitor)), params: {
      monitor: { name: "Updated Monitor Name" }
    }
    assert_redirected_to monitor_url(site_monitors(:http_monitor))
    site_monitors(:http_monitor).reload
    assert_equal "Updated Monitor Name", site_monitors(:http_monitor).name
  end

  test "update with invalid params" do
    sign_in users(:admin)
    patch monitor_url(site_monitors(:http_monitor)), params: {
      monitor: { name: "" }
    }
    assert_response :unprocessable_entity
  end

  # ── Destroy ────────────────────────────────────────────────────

  test "destroy deletes monitor" do
    sign_in users(:admin)
    assert_difference("SiteMonitor.count", -1) do
      delete monitor_url(site_monitors(:http_monitor))
    end
    assert_redirected_to monitors_url
  end

  # ── Pause / Resume / Reset ────────────────────────────────────

  test "pause pauses a monitor" do
    sign_in users(:admin)
    monitor = site_monitors(:http_monitor)
    post pause_monitor_url(monitor)
    assert_redirected_to monitor_url(monitor)
    monitor.reload
    assert_equal true, monitor.paused
    assert_equal "paused", monitor.status
  end

  test "resume resumes a paused monitor" do
    sign_in users(:admin)
    monitor = site_monitors(:paused_monitor)
    post resume_monitor_url(monitor)
    assert_redirected_to monitor_url(monitor)
    monitor.reload
    assert_equal false, monitor.paused
    assert_equal "pending", monitor.status
  end

  test "reset resets monitor failures" do
    sign_in users(:admin)
    monitor = site_monitors(:http_monitor)
    post reset_monitor_url(monitor)
    assert_redirected_to monitor_url(monitor)
    monitor.reload
    assert_equal 0, monitor.consecutive_failures
    assert_equal "pending", monitor.status
  end
end
