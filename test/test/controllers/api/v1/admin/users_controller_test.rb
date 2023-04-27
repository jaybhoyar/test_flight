# frozen_string_literal: true

require "test_helper"

class Api::V1::Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @group = create :group
    @organization = @group.organization
    @admin_role = create :organization_role_admin, organization: @organization

    @user = create :user, organization: @organization, organization_role_id: @admin_role.id
    @user_2 = create :user, organization: @organization, organization_role_id: @admin_role.id

    @agent_role = create :organization_role_agent, organization: @organization
    sign_in @user

    host! test_domain(@organization.subdomain)
    @manage_permission = Permission.find_or_create_by(name: "agents.manage_agent_details", category: "Agents")
    role = create :organization_role_admin, permissions: [@manage_permission]
    @user.update(role:)
  end

  def test_show_success
    get api_v1_admin_team_url(@user.id), headers: headers(@user)

    assert_response :ok
    assert_equal @user.id, json_body["user"]["id"]
    assert_equal @user.role_name, json_body["user"]["role"]
    assert_equal @user.first_name, json_body["user"]["first_name"]
    assert_equal [
      "id",
      "email",
      "role",
      "organization_role_id",
      "status",
      "name",
      "first_name",
      "last_name",
      "organization_url",
      "date_format",
      "time_zone",
      "is_access_locked",
      "show_keyboard_shortcuts",
      "permissions",
      "activities",
      "phone_contact_details_attributes",
      "link_contact_details_attributes",
      "profile_image_path",
      "date_time_zone_details"
    ], json_body["user"].keys
  end

  def test_update_success
    user = create :user, organization: @organization
    user_params = {
      user: {
        organization_role_id: @agent_role.id,
        first_name: "Oliver",
        last_name: "json",
        email: "oliver@example.com"
      }
    }
    patch api_v1_admin_team_url(user.id),
      params: user_params,
      headers: headers(@user)

    assert_response :ok

    assert_equal "Agent", user.reload.role_name
    assert_equal "Oliver", user.first_name
    assert_equal @agent_role.id, user.reload.role.id
  end

  def test_update_non_admin_nor_same_user_failure
    user = create :user, :admin, organization: @organization
    user_params = {
      user: {
        organization_role_id: @agent_role.id,
        first_name: "Oliver",
        last_name: "json",
        email: "oliver@example.com"
      }
    }

    agent = create :user_with_agent_role, organization: @organization
    sign_in(agent)

    patch api_v1_admin_team_url(user.id), params: user_params, headers: headers(agent)

    assert_response :forbidden
  end

  def test_that_agent_can_update_a_customer
    sign_out @user

    agent = create :user, :agent, organization: @organization
    sign_in agent

    user = create :user, organization_role_id: nil, organization: @organization
    user_params = {
      user: {
        first_name: "Oliver",
        last_name: "Sung",
        email: "oliver@example.com"
      }
    }

    patch api_v1_admin_team_url(user.id), params: user_params, headers: headers(agent)

    assert_response :success
  end

  def test_update_success_with_company
    user = create(:user, organization: @organization)
    company = create(:company)
    user_params = {
      user: {
        organization_role_id: nil,
        first_name: "Tony",
        last_name: "Stark",
        company_id: company.id,
        email: "tony@example.com"
      }
    }
    patch api_v1_admin_team_url(user.id),
      params: user_params,
      headers: headers(@user)

    user.reload

    assert_response :ok
    assert_nil user.role
    assert_equal "Tony", user.first_name
    assert_equal company.id, user.reload.company.id
  end

  # def test_update_failure
  #   user = create(:user, organization: @organization)
  #   user_params = { user: { role_id: nil } }

  #   patch api_v1_admin_team_url(user.id),
  #         params: user_params,
  #         headers: headers(@user)
  #   assert_includes json_body["errors"], "Role is not included in the list"
  # end

  def test_update_failure_due_to_short_password
    user = create(:user, organization: @organization)
    user_params = {
      user: { password: "121" }
    }

    patch api_v1_admin_team_url(user.id),
      params: user_params,
      headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Password is too short (minimum is 6 characters)"
  end

  def test_create_success
    user_params = {
      user: {
        organization_role_id: @agent_role.id,
        first_name: "Oliver",
        last_name: "Smith",
        emails: ["oliver@example.com"],
        time_zone_offset: -330
      }
    }

    post api_v1_admin_team_index_url, params: user_params, headers: headers(@user)
    assert_response :ok

    oliver = @organization.users.find_by(email: "oliver@example.com")
    assert_equal "Chennai", oliver.time_zone
    assert_equal "Agent(s) have been successfully invited.", json_body["notice"]
  end

  def test_create_only_admin_failure
    user_params = {
      user: {
        organization_role_id: @agent_role.id,
        first_name: "Oliver",
        last_name: "Smith",
        emails: "oliver@example.com"
      }
    }
    agent = create(:user_with_agent_role, organization: @organization)
    sign_in(agent)

    post api_v1_admin_team_index_url, params: user_params, headers: headers(agent)

    assert_response :forbidden
  end

  def test_add_existing_user
    user_params = {
      user: {
        organization_role_id: @admin_role.id,
        first_name: @user.first_name,
        last_name: @user.last_name,
        emails: [@user.email]
      }
    }

    post api_v1_admin_team_index_url, params: user_params, headers: headers(@user)

    assert_response :unprocessable_entity
    assert_equal "Email #{@user.email} already exists.", json_body["message"]
  end

  def test_invite_user_from_other_organizations
    organization_2 = create :organization
    user_2 = create :user_with_admin_role, organization: organization_2

    user_params = {
      user: {
        organization_role_id: @agent_role.id,
        emails: [user_2.email]
      }
    }
    post api_v1_admin_team_index_url, params: user_params, headers: headers(@user)
    assert_response :ok

    assert_equal "Agent(s) have been successfully invited.", json_body["notice"]
  end

  def test_destroy_success
    create_multiple_agents

    payload = create_multiple_agents_params(agents)

    assert_difference "User.count", -5 do
      delete destroy_multiple_api_v1_admin_team_index_url(payload), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Agents have been successfully removed.", json_body["notice"]
  end

  def test_should_not_delete_self
    payload = create_multiple_agents_params([@user])

    delete destroy_multiple_api_v1_admin_team_index_url(payload), headers: headers(@user)

    assert_response :forbidden
  end

  def test_index_success_with_no_search_term
    user = create :user, :admin, organization: @organization
    user_params = {
      user: {
        page_index: 1,
        page_size: 30,
        column: "first_name",
        direction: "desc"
      }
    }

    get api_v1_admin_team_index_url, params: user_params, headers: headers(@user)

    default_sort = @organization.users.all.order(first_name: :desc)

    assert_response :ok
    assert_equal default_sort.last.first_name, default_sort.reverse.first.first_name
    assert_equal 3, json_body["users"].size
  end

  def test_sort_with_email_asc
    create_multiple_agents

    payload = create_multiple_agents_params([@user])

    user_params = {
      page_index: 1,
      page_size: 30,
      column: "email",
      direction: "asc"
    }

    get api_v1_admin_team_index_url, params: user_params, headers: headers(@user)
    default_sort = @organization.users.order(email: :asc)

    assert_response :ok
    assert_equal default_sort.first.email, json_body["users"][0]["email"]
    assert_equal 7, json_body["users"].size
  end

  def test_index_success_with_search_term
    users = search_string_service(@user.first_name)
    assert_equal 1, users.count
  end

  def test_index_with_search_term_gives_only_activated_users
    user_params = {
      user: {
        page_index: 1,
        page_size: 30,
        search_term: @user.first_name
      }
    }

    get api_v1_admin_team_index_url, params: user_params, headers: headers(@user)

    assert_response :ok
    assert_equal false, json_body["users"][0]["is_deactivated"]
  end

  # def test_that_agent_cannot_change_role_to_owner
  #   @user.update(role_id: @agent_role.id)
  #   user = create :user, organization: @organization
  #   user_params = {
  #     user: {
  #       role: @admin_role
  #     }
  #   }
  #   patch api_v1_admin_team_url(user.id),
  #         params: user_params,
  #         headers: headers(@user)

  #   assert_response :unprocessable_entity
  #   assert_includes json_body["errors"], "Permission denied to change role"
  # end

  # 1. No warning when role is not changed
  def test_no_warning_when_role_is_not_changed
    create_roles_data

    agent = create :user, organization: @organization, role: @manage_role
    requester = create :user, organization: @organization, role: nil
    ticket = create :ticket, organization: @organization, requester: requester, agent: agent
    @group.group_members.create(user: agent)

    payload = {
      user: { organization_role_id: @manage_role.id }
    }

    patch api_v1_admin_team_url(agent.id), params: payload, headers: headers(@user)

    assert_response :ok
    assert json_body["success"]
    assert_equal "Details has been successfully updated.", json_body["notice"]
  end

  # 2. No warning when new role has permissions
  def test_no_warning_when_new_role_has_permissions
    create_roles_data

    agent = create :user, organization: @organization, role: @manage_role
    requester = create :user, organization: @organization, role: nil
    ticket = create :ticket, organization: @organization, requester: requester, agent: agent
    @group.group_members.create(user: agent)

    payload = {
      user: { organization_role_id: @manage_role_2.id }
    }

    patch api_v1_admin_team_url(agent.id), params: payload, headers: headers(@user)

    assert_response :ok
    assert json_body["success"]
    assert_equal "Details has been successfully updated.", json_body["notice"]
  end

  # 3. No warning when new role doesnt have permissions and user doesnt have any assignments
  def test_no_warning_when_new_role_doesnt_have_permissions_and_user_doesnt_have_any_assignments
    create_roles_data

    agent = create :user, organization: @organization, role: @manage_role

    payload = {
      user: { organization_role_id: @view_role.id }
    }

    patch api_v1_admin_team_url(agent.id), params: payload, headers: headers(@user)

    assert_response :ok
    assert json_body["success"]
    assert_equal "Details has been successfully updated.", json_body["notice"]
  end

  # 5. Show warning when new role doesnt have tickets permissions
  def test_show_warning_when_new_role_doesnt_have_tickets_permissions
    create_roles_data

    agent = create :user, organization: @organization, role: @manage_role
    requester = create :user, organization: @organization, role: nil
    ticket = create :ticket, organization: @organization, requester: requester, agent: agent
    @group.group_members.create(user: agent)

    payload = {
      user: { organization_role_id: @manage_chats_role.id }
    }

    patch api_v1_admin_team_url(agent.id), params: payload, headers: headers(@user)

    assert_response :ok
    assert_not json_body["success"]
    assert_equal \
      "All the assigned tickets will be marked as unassigned as the new role does not have these permissions.",
      json_body["notice"]

    # Save with verification
    payload = {
      user: { organization_role_id: @manage_chats_role.id, change_role: true }
    }

    patch api_v1_admin_team_url(agent.id), params: payload, headers: headers(@user)
    assert_response :ok
    assert json_body["success"]
    assert_equal "Details has been successfully updated.", json_body["notice"]
    assert_nil ticket.reload.agent_id
  end

  private

    def create_roles_data
      manage_desk = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")
      view_desk = Permission.find_or_create_by(name: "desk.view_tickets", category: "Desk")

      @manage_role = create :organization_role,
        name: "Supervisor",
        organization: @organization,
        permissions: [manage_desk]
      @view_role = create :organization_role,
        name: "Visiting Supervisor",
        organization: @organization,
        permissions: [view_desk]
      @manage_role_2 = create :organization_role,
        name: "Manager",
        organization: @organization,
        permissions: [manage_desk]
      @manage_desk_role = create :organization_role,
        name: "Tickets Manager",
        organization: @organization,
        permissions: [manage_desk]
      @manage_chats_role = create :organization_role,
        name: "Chats Manager",
        organization: @organization,
        permissions: [view_desk]
    end

    def create_multiple_agents
      5.times do
        create(:user, organization: @organization, role: @agent_role)
      end
    end

    def agents
      @organization.users.where(role: @agent_role)
    end

    def create_multiple_agents_params(agents)
      {
        user: {
          ids: agents.pluck(:id)
        }
      }
    end

    def random_first_name
      agents.sample.first_name
    end

    def count_of_agents_having_search_string_in_their_name(search_string)
      agents.where(
        "lower(first_name) LIKE :string OR lower(last_name) LIKE :string",
        string: "%#{search_string.downcase}%"
      ).size
    end

    def search_string_service(search_string)
      Search::User.new(@organization, search_string).search
    end
end
