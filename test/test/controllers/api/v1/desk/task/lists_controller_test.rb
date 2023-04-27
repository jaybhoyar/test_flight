# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Task::ListsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @organization = @user.organization
    sign_in(@user)

    @list = create :desk_task_list, :with_data, organization: @organization, name: "Payment tasks"

    host! test_domain(@organization.subdomain)
  end

  def test_index_success
    get api_v1_desk_task_lists_url, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["lists"].count
  end

  def test_create_success
    payload = { list: { name: "Refunds tasks" } }

    assert_difference "@organization.task_lists.count" do
      post api_v1_desk_task_lists_url(payload), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Refunds tasks", json_body["list"]["name"]
  end

  def test_create_failure
    payload = { list: { name: "Payment tasks" } }

    assert_no_difference "@organization.task_lists.count" do
      post api_v1_desk_task_lists_url(payload), headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_equal ["Name has already been taken"], json_body["errors"]
  end

  def test_show_success
    get api_v1_desk_task_list_url(@list.id), headers: headers(@user)

    assert_response :ok
    assert_equal "Payment tasks", json_body["list"]["name"]
  end

  def test_show_failure
    get api_v1_desk_task_list_url("invalid-id"), headers: headers(@user)
    assert_response :not_found
  end

  def test_delete_single_success
    payload = {
      list: {
        id: @list.id,
        name: @list.name,
        items_attributes: [
          {
            id: @list.items.first.id,
            _destroy: true
          }
        ]
      }
    }
    assert_difference "@list.items.count", -1 do
      patch api_v1_desk_task_list_url(@list.id, payload), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Task has been successfully deleted.", json_body["notice"]
  end

  def test_delete_multiple_success
    payload = {
      list: {
        id: @list.id,
        name: @list.name,
        items_attributes: [
          {
            id: @list.items.first.id,
            _destroy: true
          },
          {
            id: @list.items.second.id,
            _destroy: true
          }
        ]
      }
    }
    assert_difference "@list.items.count", -2 do
      patch api_v1_desk_task_list_url(@list.id, payload), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Tasks have been successfully deleted", json_body["notice"]
  end

  def test_update_success
    payload = {
      list: {
        id: @list.id,
        name: "Changed name"
      }
    }
    patch api_v1_desk_task_list_url(@list.id, payload), headers: headers(@user)

    assert_response :ok
    assert_equal "Tasks list has been successfully updated.", json_body["notice"]
  end

  def test_update_failure
    list_2 = create :desk_task_list, :with_data, organization: @organization, name: "Billing Checklist"

    payload = {
      list: {
        id: @list.id,
        name: list_2.name,
        items_attributes: [
          {
            id: @list.items.first.id,
            _destroy: true
          }
        ]
      }
    }
    patch api_v1_desk_task_list_url(@list.id, payload), headers: headers(@user)
    assert_response :unprocessable_entity
    assert_equal ["Name has already been taken"], json_body["errors"]
  end

  def test_that_task_list_is_destroyed
    task_list = create :desk_task_list, :with_data, organization: @organization

    delete api_v1_desk_task_list_url(task_list.id), headers: headers(@user)

    assert_response :ok
    assert_not Desk::Task::List.exists?(task_list.id)
  end
end
