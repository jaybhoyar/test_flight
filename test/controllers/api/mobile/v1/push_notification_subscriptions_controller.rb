# frozen_string_literal: true

class Api::Mobile::V1::PushNotificationSubscriptionsController < Api::V1::BaseController
  def create
    @notification_subscription = Desk::PushNotificationSubscription::CreateService.new(
      current_user,
      notification_subscription_params
    ).process

    if @notification_subscription.valid?
      render json: {
        notice: "Push Notification device registered successfully."
      }, status: :ok
    else
      render json: {
        errors: @notification_subscription.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

    def notification_subscription_params
      params.require(:push_notification_subscription).permit(:unique_handle, subscription_attributes: {})
    end
end
