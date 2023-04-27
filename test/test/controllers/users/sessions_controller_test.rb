# frozen_string_literal: true

require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    organization = create(:organization, auth_app_url: app_secrets.auth_app[:url])
    @user = create(:user, organization:, password: "test1234")

    host! test_domain(organization.subdomain)
    sign_in(@user)
  end

  def test_that_user_is_redirected_to_login_path
    old_authentication_token = @user.authentication_token
    get logout_url
    @user.reload

    assert_not_equal old_authentication_token, @user.authentication_token
    assert_redirected_to new_user_session_url
  end

  def test_that_user_is_redirected_to_auth_app_url_if_if_sso_eanbled
    Users::SessionsController.any_instance.stubs(:sso_enabled?).returns(true)
    old_authentication_token = @user.authentication_token

    get logout_url
    @user.reload

    assert_not_equal old_authentication_token, @user.authentication_token
    assert_redirected_to "#{app_secrets.auth_app[:url]}#{app_secrets.routes[:auth_app][:logout_path]}"
  end
end
