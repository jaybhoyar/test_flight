# frozen_string_literal: true

module TestFlight
  class Request
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def post(payload)
      client.connection.post(API_URL, payload)
    end
  end
end
