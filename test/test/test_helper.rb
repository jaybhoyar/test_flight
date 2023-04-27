# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
require "minitest/spec"
require "minitest/autorun"
require "mocha/minitest"
require "webmock/minitest"
require "support/helper_methods"

NeetoCommons.simplecov_config
NeetoCommons.minitest_reporters_config

WebMock.disable_net_connect!(allow_localhost: true)

if Rails.application.config.colorize_logging
  require "minitest/reporters"
  require "minitest/pride"

  # Refer https://github.com/kern/minitest-reporters#caveats
  # If you want to see full stacktrace then just use
  # MiniTest::Reporters.use!

  # MiniTest::Reporters.use! Minitest::Reporters::ProgressReporter.new,
  #                          ENV,
  #                          Minitest.backtrace_filter
end

def stub_net_http_request(method, url, body, status_code)
  stub_request(method, url)
    .with(
      headers: {
        "Accept" => "*/*",
        "User-Agent" => "Ruby"
      })
    .to_return(status: status_code, body:, headers: {})
end

def app_secrets
  Rails.application.secrets
end

def test_domain(subdomain = nil)
  if subdomain
    "#{subdomain}.neetodesk.test"
  else
    "neetodesk.test"
  end
end

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods
    include ActionMailer::TestHelper
    include ActiveSupport::Testing::TimeHelpers

    # parallelize(workers: :number_of_processors) if ENV["PARALLEL_WORKERS"]

    parallelize_setup do |worker|
    end
  end
end

FactoryBot::SyntaxRunner.class_eval do
  include ActionDispatch::TestProcess
end
