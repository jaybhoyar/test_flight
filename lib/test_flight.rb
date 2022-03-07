
require "faraday"
require "faraday_middleware"
require_relative "test_flight/engine"
require_relative "test_flight/version"

module TestFlight
  autoload :Client, "test_flight/client"
  autoload :Error, "test_flight/error.rb"
  autoload :Request, "test_flight/request"
  autoload :Notification, "test_flight/notification"

  require 'test_flight/railtie' if defined?(Rails) && Rails::VERSION::MAJOR >= 3
end
