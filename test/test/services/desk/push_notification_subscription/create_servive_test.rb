# frozen_string_literal: true

require "test_helper"

class Desk::PushNotificationSubscription::CreateServiceTest < ActiveSupport::TestCase
  def setup
    @user = create :user
    @user_second = create :user_with_agent_role
    @device_id = "DEA9F96A-1FE2-4FBF-B44D-67E96E577054d"
  end

  def test_create_notification_subscription_success_with_valid_data
    valid_data = push_notification_subscription_valid_payload
    assert_difference "PushNotificationSubscription.count", 1 do
      Desk::PushNotificationSubscription::CreateService.new(@user, valid_data).process
    end

    assert_equal @device_id, PushNotificationSubscription.last.unique_handle
  end

  def test_create_notification_subscription_should_move_with_same_unique_handle_to_new_user
    valid_data = push_notification_subscription_valid_payload
    assert_difference "PushNotificationSubscription.count", 1 do
      @subscription1 = Desk::PushNotificationSubscription::CreateService.new(@user, valid_data).process
    end

    assert_equal @device_id, @subscription1.unique_handle
    assert_equal @user.id, @subscription1.user.id

    valid_data = push_notification_subscription_valid_payload
    assert_no_difference "PushNotificationSubscription.count" do
      @subscription2 = Desk::PushNotificationSubscription::CreateService.new(
        @user_second,
        valid_data).process
    end

    assert_equal @subscription1.id, @subscription2.id
    assert_equal @device_id, @subscription2.unique_handle
    assert_equal @user_second.id, @subscription2.user.id
  end

  def test_create_notification_subscription_fails_with_same_unique_handle
    valid_data = push_notification_subscription_valid_payload
    assert_difference "PushNotificationSubscription.count", 1 do
      @subscription1 = Desk::PushNotificationSubscription::CreateService.new(@user, valid_data).process
    end

    assert_equal @device_id, @subscription1.unique_handle

    assert_no_difference "PushNotificationSubscription.count" do
      @subscription2 = Desk::PushNotificationSubscription::CreateService.new(@user, valid_data).process
    end

    assert_equal @device_id, @subscription2.unique_handle
  end

  private

    def push_notification_subscription_valid_payload
      {
        unique_handle: @device_id,
        subscription_attributes: {
          device_id: @device_id,
          token: "Apn-token"
        }
      }
    end
end
