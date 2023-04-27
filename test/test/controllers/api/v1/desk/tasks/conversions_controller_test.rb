# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Tasks::ConversionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @agent_adam = create(:user_with_agent_role)
    @organization = @agent_adam.organization
    customer_eve = create(:user, organization: @organization, role: nil)
    @ticket = create(
      :ticket, :with_desc, organization: @organization, requester: customer_eve, agent: @agent_adam,
      number: 2, category: "Questions")
    @task = @ticket.tasks.create(name: "Site installation", info: "Site installation service.")

    sign_in(@agent_adam)
    host! test_domain(@organization.subdomain)
  end

  def test_task_is_converted_to_ticket
    params = { task_id: @task.id }

    post api_v1_desk_task_conversions_url(params), headers: headers(@agent_adam)

    assert_response :ok
    assert json_body["task"]["has_converted_ticket"]
  end

  def test_create_sub_ticket_logs_activity_after_converting_to_ticket
    params = { task_id: @task.id }

    assert_difference "@ticket.task_activities.count", 1 do
      post api_v1_desk_task_conversions_url(params), headers: headers(@agent_adam)
    end

    assert_response :ok
    assert json_body["task"]["has_converted_ticket"]
  end
end
