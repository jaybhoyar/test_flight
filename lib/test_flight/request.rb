# frozen_string_literal: true

require "faraday"
require "faraday_middleware"

module TestFlight
  class Request
    API_URL = "https://neeto-notifications-staging.herokuapp.com/api/v1/push_notifications"

    def initialize(payload)
      @connection = connection
      @payload = payload
    end

    def connection
      @connection ||= Faraday.new do |conn|
        conn.request :json
        conn.response :json, content_type: "application/json"
      end
    end

    def post
      response = connection.post(API_URL, @payload)
      response.body
    end
  end
end
