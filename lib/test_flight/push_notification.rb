# frozen_string_literal: true

require_relative "request"

module TestFlight
  class PushNotification
    attr_reader :app_name, :device_platform, :device_token, :alert, :body

    def initialize(**params)
      @app_name = params[:app_name]
      @device_platform = params[:device_platform]
      @device_token = params[:device_token]
      @alert = params[:alert]
      @body = params[:body]
    end

    def send_notification
      Request.new(payload).post
    end

    def payload
      {
        notification: {
          app_name: app_name, alert: alert, body: body,
          device: { device_token: device_token, platform: device_platform }
        }
      }
    end
  end
end
