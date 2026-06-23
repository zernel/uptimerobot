require "test_helper"

class NotificationChannelTest < ActiveSupport::TestCase
  # ── Validations ──────────────────────────────────────────────────

  test "requires name" do
    channel = NotificationChannel.new(channel_type: "email", config: { address: "test@example.com" })
    assert_not channel.valid?
    assert_includes channel.errors[:name], "can't be blank"
  end

  test "requires channel_type" do
    channel = NotificationChannel.new(name: "Test", config: { address: "test@example.com" })
    assert_not channel.valid?
    assert_includes channel.errors[:channel_type], "can't be blank"
  end

  test "requires config" do
    channel = NotificationChannel.new(name: "Test", channel_type: "email")
    assert_not channel.valid?
    assert_includes channel.errors[:config], "can't be blank"
  end

  test "valid with all required attributes" do
    channel = NotificationChannel.new(
      name: "Test Channel",
      channel_type: "email",
      config: { address: "test@example.com" }
    )
    assert channel.valid?
  end

  # ── Enum ─────────────────────────────────────────────────────────

  test "channel_type enum values" do
    channel = NotificationChannel.new(
      name: "Test",
      config: { url: "https://example.com" }
    )

    %w[email slack mattermost feishu].each do |type|
      channel.channel_type = type
      assert_equal type, channel.channel_type
    end
  end

  # ── Associations ─────────────────────────────────────────────────

  test "has_many monitors through monitor_notification_channels" do
    channel = notification_channels(:email_channel)
    assert_respond_to channel, :monitors
  end

  # ── Scopes ───────────────────────────────────────────────────────

  test "enabled scope returns enabled channels" do
    enabled = NotificationChannel.enabled
    assert_includes enabled, notification_channels(:email_channel)
  end

  test "by_type scope filters by channel_type" do
    email_channels = NotificationChannel.by_type("email")
    assert_includes email_channels, notification_channels(:email_channel)
  end
end
