# frozen_string_literal: true

require "test_helper"
class Desk::Automation::Rules::SearchServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    tag = create :ticket_tag, organization: @organization
    @rule_1 = create :automation_rule, organization: @organization,
      name: "Automatiocally assign tickets to Ethan",
      description: "Assign urgent tickets to Ethan Hunt"
    group_1 = create :automation_condition_group, :match_all, rule: @rule_1
    create :automation_condition, conditionable: group_1, field: "subject", verb: "contains", value: "urgent"
    create :automation_action, rule: @rule_1, name: "set_tags", tag_ids: [tag.id], status: nil

    @rule_2 = create :automation_rule, organization: @organization,
      name: "Mark tickets as SPAM",
      description: "Mark tickets as spam when they have either offer or lottery words"
    group_2 = create :automation_condition_group, :match_all, rule: @rule_2
    create :automation_condition, conditionable: group_2, field: "email", verb: "contains", value: "@bigbinary.com"
    create :automation_action, rule: @rule_2, name: "change_ticket_status", status: "open"

    org_agent = create :user, organization: @organization
    @rule_3 = create :automation_rule, organization: @organization,
      name: "Notify John about urgent tickets",
      description: "Send email to John when urgent tickets are created"
    group_3 = create :automation_condition_group, :match_all, rule: @rule_3
    create :automation_condition, conditionable: group_3, field: "email", verb: "contains", value: "@bigbinary.com"
    create :automation_action, rule: @rule_3, name: "email_to", value: "john@example.com",
      subject: "We have received a new urgent ticket",
      body: "Please make sure {{ticket.number}} ticket is attended."
  end

  def test_that_rules_are_matched_by_name
    service = Desk::Automation::Rules::SearchService.new(@organization, nil)

    assert_empty service.search
  end

  def test_that_rules_are_matched_by_name
    service = Desk::Automation::Rules::SearchService.new(@organization, "Automatiocally")

    assert_includes service.search, @rule_1
  end

  def test_that_rules_are_matched_by_description
    service = Desk::Automation::Rules::SearchService.new(@organization, "lottery")

    assert_includes service.search, @rule_2
  end

  def test_that_rules_are_matched_by_condition_field
    service = Desk::Automation::Rules::SearchService.new(@organization, "email")

    assert_includes service.search, @rule_2
  end

  def test_that_rules_are_matched_by_condition_value
    service = Desk::Automation::Rules::SearchService.new(@organization, "bigbinary")

    assert_includes service.search, @rule_2
  end

  def test_that_rules_are_matched_by_condition_value
    service = Desk::Automation::Rules::SearchService.new(@organization, "bigbinary")

    assert_includes service.search, @rule_2
  end

  def test_that_rules_are_matched_by_action_subject
    service = Desk::Automation::Rules::SearchService.new(@organization, "We have received")

    assert_includes service.search, @rule_3
  end

  def test_that_rules_are_matched_by_action_value
    service = Desk::Automation::Rules::SearchService.new(@organization, "john")

    assert_includes service.search, @rule_3
  end
end
