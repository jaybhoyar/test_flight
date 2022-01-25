# frozen_string_literal: true
require "faraday"
require "faraday_middleware"
require_relative "test_flight/version"

module TestFlight
  autoload :Client, "test_flight/client.rb"
  autoload :Request, "test_flight/request.rb"
  autoload :Notification, "test_flight/notification.rb"
  autoload :Error, "test_flight/error.rb"
end
