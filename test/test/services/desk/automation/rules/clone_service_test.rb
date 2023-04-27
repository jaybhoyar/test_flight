# frozen_string_literal: true

require "test_helper"
class Desk::Automation::Rules::CloneServiceTest < ActiveSupport::TestCase
  def test_that_automation_rule_is_built
    automation_rule = create(:automation_rule_with_data, name: "Refund to Billing")
    rule_service = Desk::Automation::Rules::CloneService.new(automation_rule)
    rule = rule_service.build_rule

    assert rule.valid?
    assert_not_equal automation_rule, rule.name
    assert_empty rule.conditions.map(&:id).compact
    assert_empty rule.actions.map(&:id).compact
  end

  def test_that_name_in_properly_suffixed
    automation_rule = create(
      :automation_rule_with_data,
      name: "Refund to Billing - CLONED - #{Date.yesterday.to_time.to_i}")
    rule_service = Desk::Automation::Rules::CloneService.new(automation_rule)
    rule = rule_service.build_rule

    assert rule.valid?
    assert_not_equal automation_rule, rule.name
  end

  def test_that_rule_with_tag_is_cloned
    organization = create :organization
    tag = create :ticket_tag, organization: organization
    auto_rule = create :automation_rule, organization: organization, name: "Automatically assign tickets to Ethan", description: "Assign urgent tickets to Ethan Hunt"
    group = create :automation_condition_group, rule: auto_rule
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "urgent"
    create :automation_action, rule: auto_rule, name: "set_tags", tag_ids: [tag.id], status: nil

    assert_difference ["Desk::Automation::Rule.count", "Desk::Automation::ConditionGroup.count",
"Desk::Automation::Condition.count", "Desk::Automation::Action.count"] do
      rule_service = Desk::Automation::Rules::CloneService.new(auto_rule)
      rule = rule_service.build_rule
      rule.save
    end
  end
end
