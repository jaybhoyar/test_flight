# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Macros::ExecutionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in @user

    host! test_domain(@organization.subdomain)
    @ticket = create :ticket, organization: @organization, group: nil
  end

  def test_execute_macro_assign_group_success
    group = create :group, organization: @organization
    macro_assign_group = create :desk_macro_rule, :visible_to_all_agents, organization: @organization,
      name: "Thank you",
      actions_attributes: [
                              { name: "assign_group", body: "", actionable_id: group.id, actionable_type: "Group" }
                            ]

    valid_params = { ticket_id: @ticket.id }

    post api_v1_desk_macro_executions_url(macro_assign_group.id), params: valid_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal group.id, @ticket.reload.group_id
  end

  def test_that_on_error_changes_are_reverted
    create :ticket_field, agent_label: "Customer Age",
      is_required_for_agent_when_closing_ticket: true,
      organization: @organization

    group = create :group, organization: @organization
    macro_assign_group = create :desk_macro_rule, :visible_to_all_agents, organization: @organization,
      name: "Thank you",
      actions_attributes: [
                              { name: "assign_group", body: "", actionable_id: group.id, actionable_type: "Group" },
                              { name: "change_status", body: "", value: "closed" },
                            ]

    valid_params = { ticket_id: @ticket.id }

    post api_v1_desk_macro_executions_url(macro_assign_group.id), params: valid_params,
      headers: headers(@user)

    assert_response :unprocessable_entity
    assert_nil @ticket.reload.group_id
    assert_includes json_body["errors"], "Customer Age is required to close the ticket."
  end
end
