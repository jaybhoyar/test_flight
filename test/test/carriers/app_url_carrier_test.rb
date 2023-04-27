# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class AppUrlCarrierTest < ActiveSupport::TestCase
  def teardown
    # ENV["HEROKU_APP_NAME"] = nil
    ENV["RENDER_EXTERNAL_HOSTNAME"] = nil
    ENV["RENDER_SERVICE_SLUG"] = nil
    ENV["APP_URL"] = "http://app.neetodesk.test"
  end

  def test_app_url_when_heroku_app_name_env_variable_is_present
    Rails.stub(:env, ActiveSupport::StringInquirer.new("heroku")) do
      # ENV["HEROKU_APP_NAME"] = "neetodesk-staging-pr-123"
      ENV["RENDER_SERVICE_SLUG"] = "neetodesk-staging-pr-123"
      ENV["RENDER_EXTERNAL_HOSTNAME"] = "neetodesk-staging-pr-123.onrender.com"

      assert_equal AppUrlCarrier.app_url, URI("https://neetodesk-staging-pr-123.onrender.com")
    end
  end

  def test_app_url_when_app_url_env_variable_is_present
    ENV["APP_URL"] = "https://staging.neetodesk.com"

    assert_equal AppUrlCarrier.app_url, URI("https://staging.neetodesk.com")
  end

  def test_app_url_when_request_is_present
    request = ActionDispatch::Request.new(
      "rack.url_scheme" => "http",
      "HTTP_HOST" => test_domain,
    )

    app_url = AppUrlCarrier.app_url(request)

    assert_equal URI("http://neetodesk.test"), app_url
  end

  def test_app_url_when_no_environment_variable_is_set_and_request_is_absent
    # ENV["HEROKU_APP_NAME"] = nil
    ENV["RENDER_SERVICE_SLUG"] = nil
    ENV["APP_URL"] = nil

    app_url = AppUrlCarrier.app_url

    assert_equal URI("http://lvh.me:9001"), app_url
  end

  def test_app_url_extract_from_request_first
    ENV["APP_URL"] = "https://staging.neetodesk.com"

    request = ActionDispatch::Request.new(
      "rack.url_scheme" => "http",
      "HTTP_HOST" => "neetodesk.test",
    )

    app_url = AppUrlCarrier.app_url(request)

    assert_equal URI("http://neetodesk.test"), app_url
  end
end
