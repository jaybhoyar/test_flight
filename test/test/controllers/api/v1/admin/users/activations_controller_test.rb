# frozen_string_literal: true

require "test_helper"

class Api::V1::Admin::Users::ActivationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = create :organization
    @user = create :user, :admin, organization: @organization
    sign_in @user

    host! test_domain(@organization.subdomain)
  end

  def test_that_user_can_be_deactivated
    admin_role = @organization.roles.find_or_create_by(name: "Admin")
    user = create :user, role: admin_role, organization: @organization
    user_2 = create :user, role: admin_role, organization: @organization

    assert user.active?

    payload = {
      user: {
        status: "deactivate"
      }
    }

    post api_v1_admin_team_activation_url(user.id), params: payload, headers: headers(@user)

    assert_response :ok
    assert_not user.reload.active?

    assert_equal "#{user.name}'s account has been deactivated.", json_body["notice"]
  end

  def test_agent_is_unassigned_from_tickets_when_deactivated
    agent = create(:user_with_agent_role, organization: @organization)
    ticket1 = create(:ticket, organization: @organization, agent_id: agent.id)
    ticket2 = create(:ticket, organization: @organization, agent_id: agent.id)
    assert agent.active?
    payload = {
      user: {
        status: "deactivate"
      }
    }
    post api_v1_admin_team_activation_url(agent.id), params: payload, headers: headers(@user)
    ticket1.reload
    ticket2.reload

    assert_nil ticket1.agent_id
    assert_nil ticket2.agent_id
  end

  def test_that_user_can_be_activated
    user = create :user, organization: @organization, deactivated_at: Time.current
    refute user.active?

    payload = {
      user: {
        status: "activate"
      }
    }

    post api_v1_admin_team_activation_url(user.id), params: payload, headers: headers(@user)

    assert_response :ok
    assert user.reload.active?

    assert_equal "#{user.name}'s account has been activated.", json_body["notice"]
  end

  def test_that_only_active_admin_cannot_be_deactivated
    create :user, :admin, organization: @organization, deactivated_at: Time.current
    assert @user.active?

    payload = {
      user: {
        status: "deactivate"
      }
    }

    post api_v1_admin_team_activation_url(@user.id), params: payload, headers: headers(@user)

    assert_response :unprocessable_entity
    assert @user.reload.active?

    assert_includes json_body["errors"], "You cannot deactivate active admin from the organization!"
  end

  def test_that_user_is_updated_when_sso_is_enabled_auth_service_request_is_successful
    agent = create(:user_with_agent_role, organization: @organization)
    Api::V1::Admin::Users::ActivationsController.any_instance.stubs(:sso_enabled?).returns(true)
    stub_auth_server_request(agent.email, 200)

    payload = {
      user: {
        status: "deactivate"
      }
    }

    post api_v1_admin_team_activation_url(agent.id), params: payload, headers: headers(@user)

    assert_response :ok
    assert_not agent.reload.active?
  end

  private

    def stub_auth_server_request(email, response_code)
      stub_request(:put, ->(uri) { uri.to_s.include?("/api/v1/clients/users") }).with(
        body: hash_including(
          {
            "user" => hash_including(
              {
                "email" => email
              })
          }),
        headers: {
          "Authorization" => "Bearer",
          "Content-Type" => "application/x-www-form-urlencoded"
        }
      ).to_return(status: response_code, body: "", headers: {})
    end
end
