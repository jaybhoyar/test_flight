# frozen_string_literal: true

module TestFlight
  class Notification < Request
    def send(attributes)
      post("push_notifications", body: format(attributes)).body
    end

    private

    def format(attributes)
      {
        notification: {
          alert: attributes[:alert],
          body: attributes[:body],
          device: {
            device_token: attributes[:device_token],
            platform: attributes[:device_platform]
          }
        }
      }
    end
  end
end
