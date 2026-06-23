require "test_helper"

class NotificationChannelsControllerTest < ActionDispatch::IntegrationTest
  # ── Authentication ──────────────────────────────────────────────

  test "requires authentication" do
    get notification_channels_url
    assert_redirected_to new_user_session_url
  end

  # ── Index ──────────────────────────────────────────────────────

  test "index lists notification channels" do
    sign_in users(:admin)
    get notification_channels_url
    assert_response :success
  end

  # ── Show ───────────────────────────────────────────────────────

  test "show displays notification channel" do
    sign_in users(:admin)
    get notification_channel_url(notification_channels(:email_channel))
    assert_response :success
  end

  # ── New / Create ──────────────────────────────────────────────

  test "new renders form" do
    sign_in users(:admin)
    get new_notification_channel_url
    assert_response :success
  end

  test "create with valid params" do
    sign_in users(:admin)
    assert_difference("NotificationChannel.count", 1) do
      post notification_channels_url, params: {
        notification_channel: {
          name: "New Slack Channel",
          channel_type: "slack",
          config: { webhook_url: "https://hooks.slack.com/new" }
        }
      }
    end
    assert_redirected_to notification_channel_url(NotificationChannel.order(:created_at).last)
  end

  test "create with invalid params" do
    sign_in users(:admin)
    assert_no_difference("NotificationChannel.count") do
      post notification_channels_url, params: {
        notification_channel: {
          name: "",
          channel_type: "",
          config: {}
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # ── Edit / Update ─────────────────────────────────────────────

  test "edit renders form" do
    sign_in users(:admin)
    get edit_notification_channel_url(notification_channels(:email_channel))
    assert_response :success
  end

  test "update with valid params" do
    sign_in users(:admin)
    patch notification_channel_url(notification_channels(:email_channel)), params: {
      notification_channel: { name: "Updated Email Alerts" }
    }
    assert_redirected_to notification_channel_url(notification_channels(:email_channel))
    notification_channels(:email_channel).reload
    assert_equal "Updated Email Alerts", notification_channels(:email_channel).name
  end

  test "update with invalid params" do
    sign_in users(:admin)
    patch notification_channel_url(notification_channels(:email_channel)), params: {
      notification_channel: { name: "" }
    }
    assert_response :unprocessable_entity
  end

  # ── Destroy ────────────────────────────────────────────────────

  test "destroy deletes notification channel" do
    sign_in users(:admin)
    assert_difference("NotificationChannel.count", -1) do
      delete notification_channel_url(notification_channels(:email_channel))
    end
    assert_redirected_to notification_channels_url
  end
end
