# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Automation::Rules::ExecutionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user_with_agent_role)
    @organization = @user.organization
    @ticket = create(
      :ticket, organization: @organization,
      subject: "I have received my refund, done with the ticket, can be closed")
    sign_in(@user)

    host! test_domain(@organization.subdomain)
    @manage_permission = Permission.find_or_create_by(name: "admin.manage_automation_rules", category: "Admin")
    role = create :organization_role, permissions: [@manage_permission]
    @user.update(role:)
  end

  def test_that_rule_is_executed
    rule = create :automation_rule, name: "Close ticket when subject contains done", organization: @organization
    create :automation_condition, conditionable: rule, join_type: "and_operator", field: "subject", verb: "contains", value: "done"
    create :automation_action, rule: rule, name: "change_ticket_status", status: "closed"

    assert_equal @ticket.status, "open"

    assert_difference "Desk::Automation::ExecutionLogEntry.count" do
      post api_v1_desk_automation_rule_executions_url(rule.id), headers: headers(@user)
    end

    assert @ticket.reload.status_closed?
    assert_response :ok
    assert_equal "Rule has been successfully applied.", json_body["notice"]
  end

  def test_that_execution_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    rule = create :automation_rule, name: "Close ticket when subject contains done", organization: @organization
    create :automation_condition, conditionable: rule, join_type: "and_operator", field: "subject", verb: "contains", value: "done"
    create :automation_action, rule: rule, name: "change_ticket_status", status: "closed"

    post api_v1_desk_automation_rule_executions_url(rule.id), headers: headers(@user)
    assert_response :forbidden
  end
end
