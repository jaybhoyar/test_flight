# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Automation::SearchRulesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create(:organization)
    @user = create :user, organization: @organization
    sign_in(@user)

    tag = create :ticket_tag, organization: @organization
    @rule_1 = create :automation_rule, organization: @organization,
      name: "Automatically assign tickets to Ethan",
      description: "Assign urgent tickets to Ethan Hunt"

    group = create :automation_condition_group, rule: @rule_1
    create :desk_core_condition, conditionable: group, field: "subject", verb: "contains", value: "urgent"
    create :automation_action, rule: @rule_1, name: "set_tags", tag_ids: [tag.id], status: nil

    @rule_2 = create :automation_rule, organization: @organization,
      name: "Mark tickets as SPAM",
      description: "Mark tickets as spam when they have either offer or lottery words"
    group_2 = create :automation_condition_group, rule: @rule_1
    create :desk_core_condition, conditionable: group_2, field: "email", verb: "contains", value: "@bigbinary.com"
    create :automation_action, rule: @rule_2, name: "change_ticket_status", status: "open"

    host! test_domain(@organization.subdomain)
  end

  def test_that_rules_are_searched
    params = { term: "Automatically" }
    get api_v1_desk_automation_search_rules_url(params), headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["rules"].count
  end

  def test_that_rules_are_not_found_without_term
    params = { term: nil }
    get api_v1_desk_automation_search_rules_url(params), headers: headers(@user)

    assert_response :ok
    assert_equal 0, json_body["rules"].count
  end
end
