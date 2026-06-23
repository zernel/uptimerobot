require "test_helper"

class StatusPageTest < ActiveSupport::TestCase
  # ── Validations ──────────────────────────────────────────────────

  test "requires name" do
    page = StatusPage.new(slug: "test-slug")
    assert_not page.valid?
    assert_includes page.errors[:name], "can't be blank"
  end

  test "requires slug" do
    page = StatusPage.new(name: "Test Page")
    # slug should be auto-generated from name
    assert page.valid?
    assert_equal "test-page", page.slug
  end

  test "slug must be unique" do
    page = StatusPage.new(name: "Duplicate", slug: status_pages(:service_status).slug)
    assert_not page.valid?
    assert_includes page.errors[:slug], "has already been taken"
  end

  test "valid with required attributes" do
    page = StatusPage.new(name: "My Status", slug: "my-status")
    assert page.valid?
  end

  # ── Callbacks ────────────────────────────────────────────────────

  test "generate_slug sets slug from name when slug is blank" do
    page = StatusPage.new(name: "My Service Status")
    page.valid?
    assert_equal "my-service-status", page.slug
  end

  test "generate_slug does not overwrite existing slug" do
    page = StatusPage.new(name: "My Service", slug: "custom-slug")
    page.valid?
    assert_equal "custom-slug", page.slug
  end

  test "generate_slug parameterizes name" do
    page = StatusPage.new(name: "API & Web Services!")
    page.valid?
    assert_equal "api-web-services", page.slug
  end

  # ── Scopes ───────────────────────────────────────────────────────

  test "published scope returns published pages" do
    published = StatusPage.published
    assert_includes published, status_pages(:service_status)
  end

  test "draft scope returns draft pages" do
    draft = StatusPage.draft
    assert_not_includes draft, status_pages(:service_status)
  end

  # ── Associations ─────────────────────────────────────────────────

  test "has_many monitors through status_page_monitors" do
    page = status_pages(:service_status)
    page.monitors << site_monitors(:http_monitor)
    assert_includes page.reload.monitors, site_monitors(:http_monitor)
  end
end
