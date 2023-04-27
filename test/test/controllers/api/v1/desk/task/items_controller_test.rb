# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Task::ItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @organization = @user.organization
    sign_in(@user)

    @list = create :desk_task_list, :with_data, organization: @organization, name: "Payment tasks"

    host! test_domain(@organization.subdomain)
  end

  def test_create_success
    payload = {
      item: {
        list_id: @list.id,
        name: "Task 1"
      }
    }

    assert_difference "@list.items.count" do
      post api_v1_desk_task_items_url(payload), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Task 1", json_body["item"]["name"]
  end

  def test_create_failure
    create :desk_task_item, list: @list, name: "Task 1"

    payload = {
      item: {
        list_id: @list.id,
        name: "Task 1"
      }
    }

    assert_no_difference "@list.items.count" do
      post api_v1_desk_task_items_url(payload), headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_equal ["Name has already been taken"], json_body["errors"]
  end

  def test_update_success
    item = @list.items.first

    payload = {
      item: {
        list_id: @list.id,
        id: item.id,
        name: "Changed Name"
      }
    }

    patch api_v1_desk_task_item_url(item.id, payload), headers: headers(@user)

    assert_response :ok
    assert_equal "Task has been successfully updated.", json_body["notice"]
    assert_equal "Changed Name", item.reload.name
  end
end
