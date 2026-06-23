require "test_helper"

class IncidentsControllerTest < ActionDispatch::IntegrationTest
  # ── Authentication ──────────────────────────────────────────────

  test "requires authentication for index" do
    get incidents_url
    assert_redirected_to new_user_session_url
  end

  test "requires authentication for show" do
    get incident_url(incidents(:ongoing_incident))
    assert_redirected_to new_user_session_url
  end

  # ── Index ──────────────────────────────────────────────────────

  test "index lists incidents" do
    sign_in users(:admin)
    get incidents_url
    assert_response :success
  end

  test "index filters by ongoing status" do
    sign_in users(:admin)
    get incidents_url, params: { status: "ongoing" }
    assert_response :success
  end

  test "index filters by resolved status" do
    sign_in users(:admin)
    get incidents_url, params: { status: "resolved" }
    assert_response :success
  end

  test "index filters by monitor_id" do
    sign_in users(:admin)
    get incidents_url, params: { monitor_id: site_monitors(:http_monitor).id }
    assert_response :success
  end

  # ── Show ───────────────────────────────────────────────────────

  test "show displays ongoing incident" do
    sign_in users(:admin)
    get incident_url(incidents(:ongoing_incident))
    assert_response :success
  end

  test "show displays resolved incident" do
    sign_in users(:admin)
    get incident_url(incidents(:resolved_incident))
    assert_response :success
  end
end
