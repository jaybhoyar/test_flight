# frozen_string_literal: true

module TestFlight
  class Client
    BASE_URL = Rails.env.production? ? "https://neeto-notifications-staging.herokuapp.com/api/v1" : "http://localhost:9030/api/v1"

    attr_reader :api_key

    def initialize(api_key)
      @api_key = api_key
    end

    def notification
      Notification.new(self)
    end

    def connection
      puts "*" * 100
      puts BASE_URL
      puts "*" * 100
      @connection ||= Faraday.new(BASE_URL) do |conn|
        conn.adapter Faraday.default_adapter
        conn.headers["X-Api-Key"] = api_key if api_key.present?
        conn.request :json
        conn.response :json, content_type: "application/json"
      end
    end
  end
end
