# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Tickets::TaskListsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user_with_agent_role)
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_that_tasks_are_cloned_from_task_list_success
    ticket = create :ticket, organization: @organization
    tasks_list = create :desk_task_list, :with_data, organization: @organization

    payload = {
      task_list: {
        id: tasks_list.id
      }
    }
    assert_difference "ticket.tasks.count", 5 do
      post api_v1_desk_ticket_task_lists_url(ticket.id), params: payload, headers: headers(@user)
    end

    assert_response :created
    assert_equal "5 tasks have been successfully added.", json_body["notice"]
  end
end
