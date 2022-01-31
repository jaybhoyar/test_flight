# frozen_string_literal: true

module TestFlight
  class Request
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def post(url, body:, headers: {})
      puts "8"*100
      puts url
      puts "8"*100
      client.connection.post(url, body, headers)
    end
  end
end
