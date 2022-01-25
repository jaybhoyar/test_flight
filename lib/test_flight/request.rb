# frozen_string_literal: true

module TestFlight
  class Request
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def self.post(url, body:, headers: {})
      client.connection.post(url, body, headers)
    end
  end
end
