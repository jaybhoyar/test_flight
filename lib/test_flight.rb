# frozen_string_literal: true

require_relative "test_flight/version"

module TestFlight
  autoload :PushNotification, "test_flight/push_notification.rb"
  autoload :Error, "test_flight/error.rb"
end
