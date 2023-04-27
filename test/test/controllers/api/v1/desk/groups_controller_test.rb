# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::GroupsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user_with_agent_role)
    @organization = @user.organization
    @busienss_hour = create(:business_hour, organization: @organization)
    @group = create(:group, organization: @organization, business_hour: @busienss_hour, name: "Billing")
    sign_in(@user)

    host! test_domain(@organization.subdomain)
    @manage_permission = Permission.find_or_create_by(name: "admin.manage_groups", category: "Admin")
    role = create :organization_role, permissions: [@manage_permission]
    @user.update(role:)
  end

  def test_index_success
    create(:ticket, group: @group)

    get api_v1_desk_groups_url, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["groups"].size
    first_group = json_body["groups"][0]
    assert_equal ["id", "name", "description", "business_hour_id"], first_group.keys
  end

  def test_index_with_details_success
    create(:ticket, group: @group)

    get api_v1_desk_groups_url, params: { load_details: true }, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["groups"].size
    first_group = json_body["groups"][0]
    assert_equal ["id", "name", "description", "business_hour_id", "tickets_count", "members_count"], first_group.keys
  end

  def test_index_with_search
    create(:group, organization: @organization, business_hour: @busienss_hour, name: "Payments")

    get api_v1_desk_groups_url(params: { term: "bill" }), headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["groups"].size
  end

  def test_show_success
    get api_v1_desk_group_url(@group), headers: headers(@user)
    assert_response :ok
    assert_equal ["id", "name", "description", "business_hour_id", "members"], json_body["group"].keys
  end

  def test_show_failure
    get api_v1_desk_group_url(0), headers: headers(@user)
    assert_response :not_found
  end

  def test_destroy_multiple_success
    create_multiple_groups
    payload = create_multiple_groups_params(groups)

    assert_difference "Group.count", -6 do
      delete destroy_multiple_api_v1_desk_groups_url(payload), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Groups have been successfully deleted!", json_body["notice"]
  end

  def test_destroy_single_success
    create_multiple_groups
    payload = {
      group: {
        ids: [groups.first.id]
      }
    }

    assert_difference "Group.count", -1 do
      delete destroy_multiple_api_v1_desk_groups_url(payload), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Group has been successfully deleted!", json_body["notice"]
  end

  def test_that_destroy_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)
    create_multiple_groups
    payload = create_multiple_groups_params(groups)

    delete destroy_multiple_api_v1_desk_groups_url(payload), headers: headers(@user)
    assert_response :forbidden
  end

  def test_update_success
    patch api_v1_desk_group_url(@group.id),
      params: group_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal "Group has been successfully updated.", json_body["notice"]

    @group.reload
    assert_equal "Finance", @group.name
    assert_equal "Finance team", @group.description
  end

  def test_that_update_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    patch api_v1_desk_group_url(@group.id),
      params: group_params,
      headers: headers(@user)

    assert_response :forbidden
  end

  def test_update_failure
    patch api_v1_desk_group_url(@group.id),
      params: { group: { name: "" } },
      headers: headers(@user)

    assert_response :unprocessable_entity
    assert_equal ["Name can't be blank"], json_body["errors"]
  end

  def test_create_success
    assert_difference "@organization.groups.count", 1 do
      post api_v1_desk_groups_url,
        params: group_params,
        headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Group has been successfully created.", json_body["notice"]
  end

  def test_that_create_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    post api_v1_desk_groups_url,
      params: group_params,
      headers: headers(@user)

    assert_response :forbidden
  end

  def test_create_failure_when_name_field_is_blank
    assert_no_difference "@organization.groups.count" do
      post api_v1_desk_groups_url,
        params: { group: { name: "" } },
        headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_equal ["Name can't be blank"], json_body["errors"]
  end

  def test_create_failure_when_group_name_aleady_exist
    assert_no_difference "@organization.groups.count" do
      post api_v1_desk_groups_url,
        params: { group: { name: @group.name } },
        headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_equal ["Name has already been taken"], json_body["errors"]
  end

  def test_create_with_group_members
    assert_difference "@organization.groups.count", 1 do
      post api_v1_desk_groups_url,
        params: group_params_with_members,
        headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Group has been successfully created.", json_body["notice"]

    group = Group.find_by(name: "Alpha")

    assert_equal 1, group.group_members.count
    assert_equal @user, group.group_members.last.user
  end

  def test_update_with_group_members
    @group.group_members.create(user: @user)

    assert_difference "@group.group_members.count", -1 do
      patch api_v1_desk_group_url(@group.id),
        params: group_params_with_blank_members_field,
        headers: headers(@user)
    end

    @group.group_members.destroy_all

    assert_difference "@group.group_members.count", 1 do
      patch api_v1_desk_group_url(@group.id),
        params: group_params_with_members,
        headers: headers(@user)
    end
  end

  private

    def group_params
      {
        group: {
          name: "Finance",
          description: "Finance team"
        }
      }
    end

    def group_params_with_members
      {
        group: {
          name: "Alpha",
          description: "Team Alpha",
          user_ids: [ @user.id ]
        }
      }
    end

    def group_params_with_blank_members_field
      {
        group: {
          name: "Alpha",
          description: "Team Alpha",
          user_ids: []
        }
      }
    end

    def groups
      @organization.groups.all
    end

    def create_multiple_groups
      5.times do
        create(:group, organization: @organization, business_hour: @busienss_hour)
      end
    end

    def create_multiple_groups_params(groups)
      {
        group: {
          ids: groups.pluck(:id)
        }
      }
    end
end
