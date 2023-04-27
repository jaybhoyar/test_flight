# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Automation::Rules::TicketsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user_with_agent_role)
    @organization = @user.organization
    @ticket = create(
      :ticket, organization: @organization, subject: "When can I expect my refund?",
      requester: create(:user))
    create(:comment, ticket: @ticket)
    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_that_matching_tickets_are_returned
    @rule = create :automation_rule_with_data, name: "Billing", organization: @organization
    get api_v1_desk_automation_rule_tickets_url(@rule.id), headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["tickets"].count
    assert_equal @ticket.id, json_body["tickets"].first["id"]
  end

  def test_that_not_matching_tickets_are_not_showned
    ticket2 = create(:ticket, organization: @organization, subject: "When can I expect my final payment?")
    ticket3 = create(
      :ticket, organization: @organization,
      subject: "How is my issue resolution regarding refund coming up?")

    @rule = create :automation_rule_with_data, name: "Billing", organization: @organization
    get api_v1_desk_automation_rule_tickets_url(@rule.id), headers: headers(@user)

    assert_response :ok
    assert_equal 2, json_body["tickets"].count
  end

  def test_show_failure
    get api_v1_desk_automation_rule_tickets_url(0), headers: headers(@user)

    assert_response :not_found
  end
end
