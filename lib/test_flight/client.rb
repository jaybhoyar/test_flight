# frozen_string_literal: true

module TestFlight
  class Client
    BASE_URL = "http://localhost:9030/api/v1"

    attr_reader :api_key

    def initialize(api_key)
      raise "API Key is required" unless api_key

      @api_key = api_key
    end

    def notification
      Notification.new(self)
    end

    def connection
      @connection ||= Faraday.new(BASE_URL) do |conn|
        conn.adapter Faraday.default_adapter
        conn.headers["X-Api-Key"] = api_key if api_key.present?
        conn.request :json
        conn.response :json, content_type: "application/json"
      end
    end
  end
end
