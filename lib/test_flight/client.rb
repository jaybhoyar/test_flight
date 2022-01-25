# frozen_string_literal: true

module TestFlight
  class Client
    API_URL = "http://localhost:9030/api/v1/push_notifications"

    attr_reader :api_key

    def initialize(api_key)
      raise "API Key is required" unless api_key

      @api_key = api_key
    end

    def send_notification(params)
      payload = Notification.format(params)
      Request.post(payload)
    end

    def connection
      @connection ||= Faraday.new(API_URL) do |conn|
        conn.adapter Faraday.default_adapter
        conn.headers["X-Api-Key"] = api_key if api_key.present?
        conn.request :json
        conn.response :json, content_type: "application/json"
      end
    end
  end
end
