# frozen_string_literal: true

require "test_helper"

class Api::V1::Admin::OrganizationRolesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @group = create :group
    @organization = @group.organization
    @user = create(:user, organization: @organization)

    sign_in @user

    @organization_role = create(:organization_role_agent, organization: @organization)
    @customer_permissions = create(:customer_view_permissions, sequence: 1)

    @user_2 = create(:user, organization: @organization)

    host! test_domain(@organization.subdomain)
    @manage_permission = Permission.find_or_create_by(name: "admin.manage_roles", category: "Admin")
    role = create :organization_role, permissions: [@manage_permission]
    @user.update(role:)
  end

  def test_index_success
    get api_v1_admin_organization_roles_url, headers: headers(@user)

    assert_response :ok

    assert_equal 1, json_body["organization_roles"].count
    assert_equal ["agent_ids", "count", "description", "id", "kind", "name", "permission_ids"],
      json_body["organization_roles"].first.keys.sort
  end

  def test_new_success
    get new_api_v1_admin_organization_role_url, headers: headers(@user)

    assert_response :ok
    assert_equal 6, json_body["organization_role"].size
    assert_equal 1, json_body["metadata"].size
  end

  def test_new_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    get new_api_v1_admin_organization_role_url, headers: headers(@user)

    assert_response :forbidden
  end

  def test_create_success
    assert_difference "OrganizationRole.count" do
      post api_v1_admin_organization_roles_url, params: role_params, headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Role has been successfully created.", json_body["notice"]
  end

  def test_create_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    post api_v1_admin_organization_roles_url, params: role_params, headers: headers(@user)

    assert_response :forbidden
  end

  def test_create_failure_when_organization_role_name_already_exists
    assert_no_difference "OrganizationRole.count" do
      post api_v1_admin_organization_roles_url,
        params: { organization_role: { name: @organization_role.name } },
        headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_equal ["Name has already been taken"], json_body["errors"]
  end

  def create_success_with_organization_role_permissions
    OrganizationRole.delete_all

    assert_difference "OrganizationRole.count" do
      post api_v1_admin_organization_roles_url,
        params: role_params_with_permissions,
        headers: headers(@user_2)
    end

    assert_response :ok
    assert_equal "Role has been successfully created.", json_body["notice"]
    assert_equal 2, OrganizationRole.last.permissions.count
  end

  test "organization_role_show_success" do
    organization_role = create(:organization_role, organization: @organization)

    get api_v1_admin_organization_role_url(organization_role.id), headers: headers(@user)

    assert_response :ok
    assert_equal ["agent_ids", "description", "id", "kind", "name", "permission_ids"],
      json_body["organization_role"].keys.sort
    assert_equal organization_role.id, json_body["organization_role"]["id"]
  end

  test "organization_role_update_success" do
    organization_role = create(:organization_role, organization: @organization)

    patch api_v1_admin_organization_role_url(organization_role.id), params: role_params_with_permissions,
      headers: headers(@user)

    assert_response :ok
    assert_equal "Role has been successfully updated.", json_body["notice"]
  end

  test "organization_role_update_doesnt_work_without_permissions" do
    role = create :organization_role
    @user.update(role:)

    organization_role = create(:organization_role, organization: @organization)

    patch api_v1_admin_organization_role_url(organization_role.id),
      params: role_params_with_permissions,
      headers: headers(@user)

    assert_response :forbidden
  end

  test "organization_role_update_failure" do
    organization_role = create(:organization_role, :user_defined, organization: @organization)

    patch api_v1_admin_organization_role_url(organization_role.id), params: {
      organization_role:
      {
        name: "",
        description: "This role applies to all the support agents"
      }
    },
      headers: headers(@user)

    assert_response :unprocessable_entity
    assert_equal ["Name can't be blank"], json_body["errors"]
  end

  def test_destroy_success
    organization_role = create(:organization_role, :user_defined, organization: @organization)

    delete api_v1_admin_organization_role_url(organization_role.id),
      params: role_params_with_permissions,
      headers: headers(@user)

    assert_response :ok
    assert_equal "Role has been successfully deleted.", json_body["notice"]
  end

  def test_destroy_fails_when_systems_roles
    delete api_v1_admin_organization_role_url(@organization_role.id),
      params: role_params_with_permissions,
      headers: headers(@user)

    assert_response :unprocessable_entity
    assert_equal ["System roles cannot be deleted"], json_body["errors"]
  end

  def test_update_remove_manage_ticket_permissions_when_the_role_is_not_assigned_anyone
    manage_desk = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")
    role = create(:organization_role, name: "Supervisor", organization: @organization, permissions: [manage_desk])

    payload = {
      organization_role: {
        name: "Supervisor",
        description: "This role applies to all the organization supervisors",
        kind: "user_defined",
        permission_ids: []
      }
    }
    patch api_v1_admin_organization_role_url(role.id), params: payload, headers: headers(@user)

    assert_response :ok
    assert_equal "Role has been successfully updated.", json_body["notice"]
    assert_empty role.reload.permissions
  end

  def test_update_remove_manage_ticket_permissions_when_the_role_is_assigned_but_tickets_are_not_assigned_to_the_user
    manage_desk = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")
    role = create :organization_role, name: "Supervisor", organization: @organization, permissions: [manage_desk]
    user = create :user, organization: @organization, role: role

    payload = {
      organization_role: {
        name: "Supervisor",
        description: "This role applies to all the organization supervisors",
        kind: "user_defined",
        permission_ids: []
      }
    }
    patch api_v1_admin_organization_role_url(role.id), params: payload, headers: headers(@user)

    assert_response :ok
    assert_equal "Role has been successfully updated.", json_body["notice"]
    assert_empty role.reload.permissions
  end

  def test_update_remove_manage_ticket_permissions_when_the_role_is_assigned_and_tickets_are_assigned_to_the_user
    manage_desk = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")
    role = create :organization_role, name: "Supervisor", organization: @organization, permissions: [manage_desk]
    agent = create :user, organization: @organization, role: role
    requester = create :user, organization: @organization, role: nil
    ticket = create :ticket, organization: @organization, requester: requester, agent: agent

    payload = {
      organization_role: {
        name: "Supervisor",
        description: "This role applies to all the organization supervisors",
        kind: "user_defined",
        permission_ids: []
      }
    }
    patch api_v1_admin_organization_role_url(role.id), params: payload, headers: headers(@user)

    assert_response :ok
    assert_equal "All the tickets assigned to the users belonging to this role will be marked as unassigned.",
      json_body["notice"]
    assert_not json_body["success"]
  end

  def test_update_remove_manage_ticket_permissions_when_the_user_has_no_manage_tickets_permissions
    manage_desk = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")
    role = create :organization_role, name: "Supervisor", organization: @organization, permissions: [manage_desk]

    agent = create :user, organization: @organization, role: role
    requester = create :user, organization: @organization, role: nil
    ticket = create :ticket, organization: @organization, requester: requester, agent: agent
    @group.group_members.create(user: agent)

    payload = {
      organization_role: {
        name: "Supervisor",
        description: "This role applies to all the organization supervisors",
        kind: "user_defined",
        permission_ids: []
      }
    }
    patch api_v1_admin_organization_role_url(role.id), params: payload, headers: headers(@user)

    assert_response :ok
    assert_equal "All the tickets assigned to the users belonging to this role will be marked as unassigned.",
      json_body["notice"]
    assert_not json_body["success"]
  end

  def test_that_remove_manage_ticket_permissions_when_the_role_is_assigned_and_tickets_are_assigned_to_the_user
    manage_desk = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")
    role = create :organization_role, name: "Supervisor", organization: @organization, permissions: [manage_desk]
    agent = create :user, organization: @organization, role: role
    @group.group_members.create(user: agent)
    requester = create :user, organization: @organization, role: nil
    ticket = create :ticket, organization: @organization, requester: requester, agent: agent

    payload = {
      verified: true,
      organization_role: {
        name: "Supervisor",
        description: "This role applies to all the organization supervisors",
        kind: "user_defined",
        permission_ids: []
      }
    }

    assert_difference "ticket.ticket_followers.count", -1 do
      patch api_v1_admin_organization_role_url(role.id), params: payload, headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Role has been successfully updated.", json_body["notice"]
    assert json_body["success"]
    assert_nil ticket.reload.agent_id
  end

  def test_update_remove_manage_ticket_permissions
    manage_desk = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")
    role = create :organization_role, name: "Supervisor", organization: @organization, permissions: [manage_desk]

    agent = create :user, organization: @organization, role: role
    requester = create :user, organization: @organization, role: nil
    ticket = create :ticket, organization: @organization, requester: requester, agent: agent
    @group.group_members.create(user: agent)
    payload = {
      verified: true,
      organization_role: {
        name: "Supervisor",
        description: "This role applies to all the organization supervisors",
        kind: "user_defined",
        permission_ids: []
      }
    }
    patch api_v1_admin_organization_role_url(role.id), params: payload, headers: headers(@user)

    assert_response :ok
    assert_equal "Role has been successfully updated.", json_body["notice"]
    assert json_body["success"]
    assert_nil ticket.reload.agent_id
  end

  private

    def role_params
      {
        organization_role: {
          name: "Supervisor",
          description: "This role applies to all the organization supervisors",
          kind: "user_defined",
          agent_ids: [@user.id]
        }
      }
    end

    def role_params_with_permissions
      {
        organization_role: {
          name: "Support",
          description: "This role applies to all the support agents",
          kind: "user_defined",
          agent_ids: [@user_2.id],
          permission_ids: [@customer_permissions.id]
        }
      }
    end
end
