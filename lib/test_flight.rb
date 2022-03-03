
require "faraday"
require "faraday_middleware"
require "test_flight/engine"
require_relative "test_flight/version"

module TestFlight
  autoload :Client, "test_flight/client"
  autoload :Error, "test_flight/error.rb"
  autoload :Request, "test_flight/request"

  autoload :Notification, "test_flight/notification"
end
