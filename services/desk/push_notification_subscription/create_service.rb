# frozen_string_literal: true

class Desk::PushNotificationSubscription::CreateService
  attr_reader :user, :notification_subscription_params

  def initialize(user, notification_subscription_params)
    @user = user
    @notification_subscription_params = notification_subscription_params
  end

  def process
    check_and_move_subscription_to_user
    create_subscription if notification_subscription.blank?
    notification_subscription
  end

  private

    def notification_subscription
      @notification_subscription ||= ::PushNotificationSubscription
        .find_by(unique_handle: notification_subscription_params[:unique_handle])
    end

    def check_and_move_subscription_to_user
      # if multiple accounts used same device
      if notification_subscription && notification_subscription.user_id != user.id
        @notification_subscription.update(user_id: user.id)
      end
    end

    def create_subscription
      @notification_subscription ||= user
        .push_notification_subscriptions.create(notification_subscription_params)
    end
end
