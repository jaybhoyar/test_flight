# frozen_string_literal: true

require "test_helper"

class Api::V1::Admin::Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = create(:organization)

    host! test_domain(@organization.subdomain)
  end

  def test_user_session_create_success
    user = create(:user, :admin, organization: @organization)
    payload = {
      user: {
        email: user.email, password: user.password,
        organization_id: @organization.id
      }
    }

    post api_v1_users_sign_in_url, params: payload

    assert_response :ok
    assert json_body["auth_token"]
  end

  def test_that_customer_cannot_login
    user = create(:user, role: nil, organization: @organization)
    payload = {
      user: {
        email: user.email, password: user.password,
        organization_id: @organization.id
      }
    }

    post api_v1_users_sign_in_url, params: payload

    assert_response :unauthorized
    assert_equal "Incorrect email or password", json_body["error"]
  end

  def test_user_session_create_fails
    user = create :user, :admin, organization: @organization
    payload = {
      user: {
        email: user.email, password: "WrongPassword",
        organization_id: @organization.id
      }
    }

    post api_v1_users_sign_in_url, params: payload

    assert_response :unauthorized
    assert_equal "Incorrect email or password.", json_body["error"]
  end

  def test_that_locked_user_cannot_login
    user = create(:user, :admin, organization: @organization, locked_at: Time.current)
    payload = {
      user: {
        email: user.email, password: user.password,
        organization_id: @organization.id
      }
    }

    post api_v1_users_sign_in_url, params: payload

    assert_response :unauthorized
    assert_equal "Your account is locked.", json_body["error"]
  end

  def test_that_deactivated_user_cannot_login
    user = create(:user, :admin, organization: @organization, deactivated_at: Time.current)
    payload = {
      user: {
        email: user.email, password: user.password,
        organization_id: @organization.id
      }
    }

    post api_v1_users_sign_in_url, params: payload

    assert_response :unauthorized
    assert_equal "Your account is deactivated. Please contact admin.", json_body["error"]
  end

  def test_should_redirect_user_to_profile_if_not_permitted_to_view_tickets
    user = create(:user, :admin, organization: @organization)
    payload = {
      user: {
        email: user.email, password: user.password,
        organization_id: @organization.id
      }
    }
    post api_v1_users_sign_in_url, params: payload

    assert_response :ok
    assert_equal "/my/preferences", json_body["redirect_to"]
  end
end
