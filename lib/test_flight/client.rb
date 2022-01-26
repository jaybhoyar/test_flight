# frozen_string_literal: true

module TestFlight
  class Client
    attr_reader :api_key

    def initialize(api_key)
      raise "API Key is required" unless api_key

      @api_key = api_key
    end

    def self.send_notification(attributes)
      puts attributes
      payload = Notification.format(attributes)
      puts attributes
      Request.post(payload)
    end

    def connection
      @connection ||= Faraday.new do |conn|
        conn.adapter Faraday.default_adapter
        conn.headers["X-Api-Key"] = api_key if api_key.present?
        conn.request :json
        conn.response :json, content_type: "application/json"
      end
    end
  end
end
