require "test_helper"

class PublicStatusPagesControllerTest < ActionDispatch::IntegrationTest
  # ── No Authentication Required ──────────────────────────────────

  test "does not require authentication" do
    get public_status_page_url(slug: status_pages(:service_status).slug)
    assert_response :success
  end

  # ── Published Status Page ──────────────────────────────────────

  test "shows published status page" do
    get public_status_page_url(slug: status_pages(:service_status).slug)
    assert_response :success
  end

  # ── Unpublished Status Page ────────────────────────────────────

  test "returns 404 for unpublished status page" do
    status_pages(:service_status).update!(published: false)
    get public_status_page_url(slug: status_pages(:service_status).slug)
    assert_response :not_found
  end

  test "returns 404 for nonexistent slug" do
    get public_status_page_url(slug: "nonexistent-slug-999")
    assert_response :not_found
  end
end
