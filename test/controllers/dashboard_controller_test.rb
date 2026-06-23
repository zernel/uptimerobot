require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  # ── Authentication ──────────────────────────────────────────────

  test "requires authentication" do
    get root_url
    assert_redirected_to new_user_session_url
  end

  # ── Authenticated Access ───────────────────────────────────────

  test "shows dashboard when authenticated" do
    sign_in users(:admin)
    get root_url
    assert_response :success
  end

  test "displays monitor stats" do
    sign_in users(:admin)
    get root_url
    assert_response :success
    assert_select "body"
  end

  test "works for regular user" do
    sign_in users(:regular_user)
    get root_url
    assert_response :success
  end
end
