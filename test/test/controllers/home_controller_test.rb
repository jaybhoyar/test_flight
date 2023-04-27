# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @organization = @user.organization

    host! test_domain(@organization.subdomain)
  end

  def test_that_logged_in_users_are_redirected_to_unresolved_tickets
    sign_in @user

    @desk_permission_1 = Permission.find_or_create_by(name: "desk.view_tickets", category: "Desk")
    @desk_permission_2 = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")
    role = create :organization_role, permissions: [@desk_permission_1, @desk_permission_2]
    @user.update(role:)

    get root_url
    assert_redirected_to "#{@organization.root_url}desk/tickets/filters/unresolved"
  end

  def test_that_logged_in_users_without_ticket_permissions_are_redirected_to_profile
    sign_in @user

    get root_url
    assert_redirected_to "#{@organization.root_url}my/preferences"
  end

  def test_that_users_are_redirected_to_error_url_when_invalid_subdomain_is_entered
    app_secrets = Rails.application.secrets
    invalid_subdomain = "invalid-subdomain"
    auth_subdomain_url = app_secrets.auth_app[:url].gsub(app_secrets.app_subdomain, invalid_subdomain)

    host! "#{invalid_subdomain}.neetodesk.test"
    get root_url

    assert_redirected_to app_secrets.auth_app[:url]
  end

  def test_that_users_are_redirected_to_signin_url
    get root_url
    assert_redirected_to "#{@organization.root_url}users/sign_in"
  end

  def test_that_users_are_redirected_to_sso_url_when_sso_enabled
    AuthenticationFailureApp.any_instance.stubs(:sso_enabled?).returns(true)

    get root_url
    assert_redirected_to user_doorkeeper_omniauth_authorize_url
  end

  def test_that_redirected_to_auth_server_if_organization_is_not_active
    @organization.update(cancelled_at: DateTime.now, status: Organization.statuses[:cancelled])

    get root_url

    assert_redirected_to app_secrets.auth_app[:url]
  end

  def test_redirected_to_website_when_www_subdomain
    host! "www.#{test_domain}"

    get root_url

    assert_redirected_to app_secrets.website_url
  end
end
