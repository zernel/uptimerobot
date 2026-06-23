require "test_helper"

class StatusPagesControllerTest < ActionDispatch::IntegrationTest
  # ── Authentication ──────────────────────────────────────────────

  test "requires authentication" do
    get status_pages_url
    assert_redirected_to new_user_session_url
  end

  # ── Index ──────────────────────────────────────────────────────

  test "index lists status pages" do
    sign_in users(:admin)
    get status_pages_url
    assert_response :success
  end

  # ── Show ───────────────────────────────────────────────────────

  test "show displays status page" do
    sign_in users(:admin)
    get status_page_url(status_pages(:service_status))
    assert_response :success
  end

  # ── New / Create ──────────────────────────────────────────────

  test "new renders form" do
    sign_in users(:admin)
    get new_status_page_url
    assert_response :success
  end

  test "create with valid params" do
    sign_in users(:admin)
    assert_difference("StatusPage.count", 1) do
      post status_pages_url, params: {
        status_page: {
          name: "New Status Page",
          slug: "new-status-page"
        }
      }
    end
    assert_redirected_to status_page_url(StatusPage.order(:created_at).last)
  end

  test "create with invalid params" do
    sign_in users(:admin)
    assert_no_difference("StatusPage.count") do
      post status_pages_url, params: {
        status_page: {
          name: "",
          slug: ""
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # ── Edit / Update ─────────────────────────────────────────────

  test "edit renders form" do
    sign_in users(:admin)
    get edit_status_page_url(status_pages(:service_status))
    assert_response :success
  end

  test "update with valid params" do
    sign_in users(:admin)
    patch status_page_url(status_pages(:service_status)), params: {
      status_page: { name: "Updated Status Page" }
    }
    assert_redirected_to status_page_url(status_pages(:service_status))
    status_pages(:service_status).reload
    assert_equal "Updated Status Page", status_pages(:service_status).name
  end

  test "update with invalid params" do
    sign_in users(:admin)
    patch status_page_url(status_pages(:service_status)), params: {
      status_page: { name: "" }
    }
    assert_response :unprocessable_entity
  end

  # ── Destroy ────────────────────────────────────────────────────

  test "destroy deletes status page" do
    sign_in users(:admin)
    assert_difference("StatusPage.count", -1) do
      delete status_page_url(status_pages(:service_status))
    end
    assert_redirected_to status_pages_url
  end

  # ── Preview ────────────────────────────────────────────────────

  test "preview renders status page" do
    sign_in users(:admin)
    get preview_status_page_url(status_pages(:service_status))
    assert_response :success
  end
end
