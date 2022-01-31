# frozen_string_literal: true

module TestFlight
  class Client
    BASE_URL = "http://localhost:9030/api/v1"
    STAGING_URL = "https://neeto-notifications-staging.herokuapp.com/api/v1"

    attr_reader :api_key, :api_url

    def initialize(api_key)
      @api_key = api_key
      @api_url = pn_api_url
    end

    def pn_api_url
      if (ENV["RAILS_ENV"] == "development") || (ENV["RAILS_ENV"] == "staging")
        puts "#{ENV['RAILS_ENV']}"
        BASE_URL
      elsif ENV["RAILS_ENV"] == "production"
        puts ENV["RAILS_ENV"]
        STAGING_URL
      end
    end

    def notification
      Notification.new(self)
    end

    def connection
      @connection ||= Faraday.new(api_url) do |conn|
        conn.adapter Faraday.default_adapter
        conn.headers["X-Api-Key"] = api_key if api_key.present?
        conn.request :json
        conn.response :json, content_type: "application/json"
      end
    end
  end
end
