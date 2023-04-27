# frozen_string_literal: true

require "test_helper"
class Api::V1::Desk::AgentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization

    @permission_1 = Permission.find_or_create_by(name: "desk.view_tickets", category: "Desk")
    @permission_2 = Permission.find_or_create_by(name: "desk.reply_add_note_to_tickets", category: "Desk")
    @permission_3 = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")
    @agent_role = create :organization_role,
      name: "Agent",
      permissions: [@permission_1, @permission_2, @permission_3],
      organization: @organization
    @user.update(role: @agent_role)

    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_index_success_without_filters
    get api_v1_desk_agents_url, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["agents"].size
    assert_equal @user.name, json_body["agents"][0]["name"]
    assert_equal @user.available_for_desk, json_body["agents"][0]["available_for_desk"]
    assert_equal @user.continue_assigning_tickets, json_body["agents"][0]["continue_assigning_tickets"]
    assert_equal @user.group_ids, json_body["agents"][0]["group_ids"]
  end

  def test_that_agents_having_permission_are_shown_as_agents
    role_1 = create :organization_role, :user_defined,
      name: "Viewer",
      organization: @organization,
      permissions: [@permission_1]

    role_2 = create :organization_role, :user_defined,
      name: "Replier",
      organization: @organization,
      permissions: [@permission_2]

    user_1 = create :user, role: role_1, organization: @organization
    user_2 = create :user, role: role_2, organization: @organization

    get api_v1_desk_agents_url, headers: headers(@user)

    assert_response :ok
    assert_equal 2, json_body["agents"].size
  end

  def test_index_success_with_filters
    agent_filter_params = { search_string: @user.first_name }
    get api_v1_desk_agents_url,
      params: { filters: agent_filter_params },
      headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["agents"].size

    agent_filter_params = { search_string: "zzzzzzzzzz" }
    get api_v1_desk_agents_url,
      params: { filters: agent_filter_params },
      headers: headers(@user)

    assert_response :ok
    assert_empty json_body["agents"]
  end
end
