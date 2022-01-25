# frozen_string_literal: true

module TestFlight
  class Request
    API_URL = "http://localhost:9030/api/v1/push_notifications"
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def self.post(payload)
      client.connection.post(API_URL, payload)
    end
  end
end
