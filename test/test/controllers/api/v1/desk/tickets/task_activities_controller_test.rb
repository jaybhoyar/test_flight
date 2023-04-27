# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Tickets::TaskActivitiesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @agent_adam = create(:user_with_agent_role)
    @organization = @agent_adam.organization
    customer_eve = create(:user, organization: @organization, role: nil)
    @ticket = create(
      :ticket, organization: @organization, requester: customer_eve, agent: @agent_adam, number: 2,
      category: "Questions")
    User.current = @agent_adam

    host! test_domain(@organization.subdomain)
    sign_in(@agent_adam)
  end

  def test_task_activities_response
    task = @ticket.tasks.create(name: "Call customer")
    task.update!(name: "Call customer on skype.", status: "wont_do")
    task.destroy

    get api_v1_desk_ticket_task_activities_url(@ticket), headers: headers(@agent_adam)

    assert_response :ok
    assert_equal 4, json_body["task_activities"].count
  end
end
