# frozen_string_literal: true

class Desk::Users::SendPushNotificationsService
  attr_reader :user, :client

  def initialize(user)
    @user = user
    @client = NeetoNotifications::Client.new(api_key: ENV["NEETO_NOTIFICATIONS_API_KEY"])
  end

  def notify(alert, body)
    client.notification.send \
      user:,
      payload: { title: alert, body: }
  end
end
