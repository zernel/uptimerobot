require "test_helper"

class UserTest < ActiveSupport::TestCase
  # ── Devise ───────────────────────────────────────────────────────

  test "valid user with email and password" do
    user = User.new(email: "new@example.com", password: "password123", password_confirmation: "password123")
    assert user.valid?
  end

  test "requires email" do
    user = User.new(password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires valid email format" do
    user = User.new(email: "not-an-email", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "email must be unique" do
    user = User.new(email: users(:admin).email, password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "requires password with minimum length" do
    user = User.new(email: "new@example.com", password: "short")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 6 characters)"
  end

  # ── Associations ─────────────────────────────────────────────────

  test "has_many api_keys" do
    user = users(:admin)
    assert_respond_to user, :api_keys
    assert_kind_of ActiveRecord::Associations::CollectionProxy, user.api_keys
  end

  # ── Instance Methods ─────────────────────────────────────────────

  test "admin? returns true for admin user" do
    assert users(:admin).admin?
  end

  test "admin? returns false for regular user" do
    assert_not users(:regular_user).admin?
  end
end
