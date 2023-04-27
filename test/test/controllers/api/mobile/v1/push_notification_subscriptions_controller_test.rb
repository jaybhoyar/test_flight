# frozen_string_literal: true

require "test_helper"

class Api::Mobile::V1::PushNotificationSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @organization = @user.organization
    sign_in(@user)
    @device_id = "DEA9F96A-1FE2-4FBF-B44D-67E96E577054d"

    host! test_domain(@organization.subdomain)
  end

  def test_create_push_notification_subscription_success
    assert_difference -> { PushNotificationSubscription.count }, 1 do
      post api_mobile_v1_push_notification_subscriptions_url,
        params: push_notification_subscription_valid_payload,
        headers: headers(@user)

      assert_response :ok
      assert_equal "Push Notification device registered successfully.", json_body["notice"]
    end
  end

  def test_create_push_notification_subscription_fails_invalid_handle
    assert_no_difference "Ticket.count" do
      post api_mobile_v1_push_notification_subscriptions_url,
        params: push_notification_subscription_invalid_payload,
        headers: headers(@user)
    end
    assert_response :unprocessable_entity
    assert_equal ["Unique handle can't be blank"], json_body["errors"]
  end

  private

    def push_notification_subscription_valid_payload
      {
        push_notification_subscription: {
          unique_handle: @device_id,
          subscription_attributes: {
            device_id: @device_id,
            token: "Apn-token"
          }
        }
      }
    end

    def push_notification_subscription_invalid_payload
      {
        push_notification_subscription: {
          unique_handle: "",
          subscription_attributes: {
            device_id: @device_id,
            token: "Apn-token"
          }
        }
      }
    end
end
