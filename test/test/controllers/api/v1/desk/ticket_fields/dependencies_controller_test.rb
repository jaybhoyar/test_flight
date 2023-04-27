# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::TicketFields::DependenciesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_dependencies_list
    field_1 = create :ticket_field, organization: @organization
    ticket = create :ticket, organization: @organization
    create :ticket_field_response, owner: ticket, ticket_field: field_1

    rule = create :automation_rule, organization: @organization
    group_1 = create :automation_condition_group, rule: rule
    create :automation_condition, conditionable: group_1, field: field_1.id, verb: "is", value: "xxx"
    create :automation_action, rule: rule

    reply = create :automation_rule, name: "[Reply] Test", organization: @organization
    group_2 = create :automation_condition_group, rule: reply
    create :automation_condition, conditionable: group_2, field: field_1.id, verb: "is", value: "xxx"
    create :automation_action, rule: reply

    view = create :view, title: "Tickets from Mumbai", organization: @organization
    view_rule = create :view_rule, name: "Tickets from Mumbai", organization: @organization, view: view
    create :automation_condition, conditionable: view_rule, field: field_1.id, verb: "is", value: "xxx"

    get api_v1_desk_ticket_field_dependencies_url(field_1), headers: headers(@user)

    assert_response :ok
    assert_equal 3, json_body["dependencies"].count
    assert_equal 1, json_body["affected_tickets_count"]

    dependency_ids = json_body["dependencies"].map { |depend| depend["id"] }
    assert_includes dependency_ids, rule.id
    assert_includes dependency_ids, reply.id
  end

  def test_dependencies_list_is_empty_for_unused_field
    field_1 = create :ticket_field, organization: @organization
    ticket = create :ticket, organization: @organization
    ticket_2 = create :ticket, organization: @organization
    create :ticket_field_response, owner: ticket, ticket_field: field_1
    create :ticket_field_response, owner: ticket_2, ticket_field: field_1

    rule = create :automation_rule, organization: @organization
    group = create :automation_condition_group, rule: rule
    create :automation_condition, conditionable: group, field: "subject", verb: "is", value: "urgent"
    create :automation_action, rule: rule

    get api_v1_desk_ticket_field_dependencies_url(field_1), headers: headers(@user)

    assert_response :ok
    assert_equal 0, json_body["dependencies"].count
    assert_equal 2, json_body["affected_tickets_count"]
  end
end
