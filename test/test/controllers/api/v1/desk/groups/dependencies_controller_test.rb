# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Groups::DependenciesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_dependencies_list
    group = create :group, name: "HR", organization: @organization
    ticket = create :ticket, organization: @organization, group: group

    rule_1 = create :automation_rule, name: "Rule 1", organization: @organization
    rule_group_1 = create :automation_condition_group, rule: rule_1
    create :automation_condition, conditionable: rule_group_1, field: "group_id", verb: "is", value: group.id
    create :automation_action, rule: rule_1, name: "assign_group", actionable: group

    rule_2 = create :automation_rule, name: "Rule 2", organization: @organization
    rule_group_2 = create :automation_condition_group, rule: rule_2
    create :automation_condition, conditionable: rule_group_2, field: "group_id", verb: "is", value: group.id
    create :automation_action, rule: rule_2

    rule_3 = create :automation_rule, name: "Rule 3", organization: @organization
    rule_group_3 = create :automation_condition_group, rule: rule_3
    create :automation_condition, conditionable: rule_group_3
    create :automation_action, rule: rule_3, name: "assign_group", actionable: group

    view = create :view, title: "View", organization: @organization
    view_rule = create :view_rule, name: "View", organization: @organization, view: view
    create :automation_condition, conditionable: view_rule, field: "group_id", verb: "is", value: group.id

    canned_response = create :desk_macro_rule, name: "Canned Response", organization: @organization
    create :desk_macro_action, rule: canned_response, name: "assign_group", actionable: group

    get api_v1_desk_group_dependencies_url(group), headers: headers(@user)

    assert_response :ok

    assert_equal 3, json_body["dependencies"]["rules"].count
    assert_equal 1, json_body["dependencies"]["canned_responses"].count
    assert_equal 1, json_body["dependencies"]["views"].count
  end

  def test_dependencies_list_is_empty_for_unused_group
    group = create :group, name: "HR", organization: @organization

    get api_v1_desk_group_dependencies_url(group), headers: headers(@user)

    assert_response :ok

    assert_empty json_body["dependencies"]
  end
end
