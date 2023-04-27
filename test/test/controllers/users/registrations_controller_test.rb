# frozen_string_literal: true

require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    host! test_domain("www")
  end

  def test_that_user_is_redirected_to_website_url_if_sso_enabled
    Users::RegistrationsController.any_instance.stubs(:sso_enabled?).returns(true)

    get new_user_registration_url

    assert_redirected_to app_secrets.website_url
  end
end
