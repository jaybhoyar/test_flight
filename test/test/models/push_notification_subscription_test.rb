# frozen_string_literal: true

require "test_helper"

class PushNotificationSubscriptionTest < ActiveSupport::TestCase
  def test_valid_record_visibility
    push_notification_subscription = create(:push_notification_subscription)

    assert push_notification_subscription.valid?
  end

  def test_invalid_record_visibility
    push_notification_subscription = PushNotificationSubscription.new

    assert_not push_notification_subscription.valid?
    assert_includes push_notification_subscription.errors.full_messages, "Unique handle can't be blank"
    assert_includes push_notification_subscription.errors.full_messages, "User must exist"
  end
end
