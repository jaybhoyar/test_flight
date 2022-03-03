# frozen_string_literal: true

module TestFlight
  class Client
    BASE_URL = "https://neeto-notifications-staging.herokuapp.com/api/v1"

    attr_reader :api_key

    def initialize(api_key:)
      @api_key = api_key
    end

    def notification
      Notification.new(self)
    end

    def connection
      @connection ||= Faraday.new(BASE_URL) do |conn|
        conn.headers["X-Api-Key"] = api_key
        conn.request :json
        conn.response :json, content_type: "application/json"
        conn.adapter Faraday.default_adapter
      end
    end
  end
end
