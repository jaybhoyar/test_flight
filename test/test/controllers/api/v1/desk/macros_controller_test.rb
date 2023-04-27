# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::MacrosControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in @user

    host! test_domain(@organization.subdomain)
    @manage_permission = Permission.find_or_create_by(name: "admin.manage_canned_responses", category: "Admin")
    role = create :organization_role, permissions: [@manage_permission]
    @user.update(role:)
  end

  def test_index_success
    create_macros

    get api_v1_desk_macros_url, headers: headers(@user)

    assert_response :ok
    assert_equal 3, json_body["macros"].count

    assert json_body["macros"]
    assert_equal ["created_at", "description", "id", "name"], json_body["macros"][0].keys.sort
  end

  def test_create_success
    post api_v1_desk_macros_url, params: good_payload, headers: headers(@user)

    assert_response :ok
    assert_equal "Canned response has been successfully created.", json_body["notice"]
  end

  def test_that_create_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)
    post api_v1_desk_macros_url, params: good_payload, headers: headers(@user)

    assert_response :forbidden
  end

  def test_that_create_fails
    bad_payload = {
      macro: {
        name: nil,
        actions_attributes: [
          { name: "change_status", value: "Resolved" },
        ],
        record_visibility_attributes: {
          visibility: :all_agents
        }
      }
    }

    post api_v1_desk_macros_url, params: bad_payload, headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Name is required"
  end

  def test_show_success
    create_single_macro

    get api_v1_desk_macro_url(@macro_1), headers: headers(@user)

    assert_response :ok

    assert json_body["macro"]
    assert_equal ["actions", "description", "id", "name", "record_visibility"], json_body["macro"].keys.sort
  end

  def test_update_success
    create_single_macro

    good_payload = {
      macro: {
        id: @macro_1.id,
        name: "Feedback & Much more",
        actions_attributes: [
          { id: @macro_1.actions.first.id, name: "change_status", value: "Resolved" },
          { name: "change_priority", value: "High" },
        ]
      }
    }

    patch api_v1_desk_macro_url(@macro_1), params: good_payload, headers: headers(@user)

    assert_response :ok
    assert_equal "Canned response has been successfully updated.", json_body["notice"]
  end

  def test_that_update_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    create_single_macro

    good_payload = {
      macro: {
        id: @macro_1.id,
        name: "Feedback & Much more",
        actions_attributes: [
          { id: @macro_1.actions.first.id, name: "change_status", value: "Resolved" },
          { name: "change_priority", value: "High" },
        ]
      }
    }

    patch api_v1_desk_macro_url(@macro_1), params: good_payload, headers: headers(@user)

    assert_response :forbidden
  end

  def test_update_fails
    create_single_macro

    bad_payload = {
      macro: {
        id: @macro_1.id,
        name: "Feedback & Much more",
        actions_attributes: [
          { id: @macro_1.actions.first.id, name: nil, value: "Resolved" }
        ]
      }
    }

    patch api_v1_desk_macro_url(@macro_1), params: bad_payload, headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Actions name can't be blank"
  end

  def test_destroy_multiple
    create_macros

    payload = {
      macro: {
        ids: [@macro_1.id, @macro_2.id]
      }
    }
    assert_difference "@organization.desk_macros.count", -2 do
      delete destroy_multiple_api_v1_desk_macros_url, params: payload, headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Canned responses have been successfully deleted.", json_body["notice"]
  end

  def test_that_destroy_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)
    create_macros

    payload = {
      macro: {
        ids: [@macro_1.id, @macro_2.id]
      }
    }
    delete destroy_multiple_api_v1_desk_macros_url, params: payload, headers: headers(@user)
    assert_response :forbidden
  end

  private

    def create_macros
      create_single_macro

      @macro_2 = create :desk_macro_rule, organization: @organization,
        name: "Set Priority to High",
        actions_attributes: [
                          { name: "change_priority", value: "high" }
                        ],
        record_visibility_attributes: {
          visibility: :all_agents
        }
      @macro_3 = create :desk_macro_rule, organization: @organization,
        name: "Mark Solved",
        actions_attributes: [
                          { name: "change_status", value: "Solved" }
                        ],
        record_visibility_attributes: {
          creator_id: @user.id,
          visibility: :all_agents
        }

      # Created by other user as visible to self
      user_2 = create :user, :agent, organization: @organization
      @macro_4 = create :desk_macro_rule, organization: @organization,
        name: "Send rocket to space",
        actions_attributes: [
                          { name: "change_status", value: "Solved" }
                        ],
        record_visibility_attributes: {
          creator_id: user_2.id,
          visibility: :myself
        }
    end

    def create_single_macro
      @macro_1 = create :desk_macro_rule, organization: @organization,
        name: "Feedback",
        actions_attributes: [
                          { name: "add_reply", body: "Thank you for your feedback!" }
                        ],
        record_visibility_attributes: {
          visibility: :all_agents
        }
    end

    def good_payload
      {
        macro: {
          name: "Send for payout",
          description: "Assign ticket to the payments team",
          actions_attributes: [
            { name: "change_status", value: "Resolved" },
            { name: "change_priority", value: "Urgent" },
            { name: "add_reply", body: "We have verified this case. It is eligible for the payout." }
          ],
          record_visibility_attributes: {
            visibility: :all_agents
          }
        }
      }
    end
end
