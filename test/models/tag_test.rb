require "test_helper"

class TagTest < ActiveSupport::TestCase
  # ── Validations ──────────────────────────────────────────────────

  test "requires name" do
    tag = Tag.new
    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test "name must be unique" do
    tag = Tag.new(name: tags(:production).name)
    assert_not tag.valid?
    assert_includes tag.errors[:name], "has already been taken"
  end

  test "valid with unique name" do
    tag = Tag.new(name: "unique-tag")
    assert tag.valid?
  end

  # ── Associations ─────────────────────────────────────────────────

  test "has_many monitors through monitor_tags" do
    tag = tags(:production)
    tag.monitors << site_monitors(:http_monitor)
    assert_includes tag.reload.monitors, site_monitors(:http_monitor)
  end
end
