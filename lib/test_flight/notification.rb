# frozen_string_literal: true

require_relative "request"

module TestFlight
  class Notification
    def self.format(attributes)
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
