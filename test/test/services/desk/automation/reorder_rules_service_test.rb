# frozen_string_literal: true

require "test_helper"
class Desk::Automation::ReorderRulesServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization

    @rule_1 = create :automation_rule_with_data, name: "Rule 1", organization: @organization
    @rule_2 = create :automation_rule_with_data, name: "Rule 2", organization: @organization
    @rule_3 = create :automation_rule_with_data, name: "Rule 3", organization: @organization
  end

  def test_that_rules_are_reordered
    assert_no_difference ["Desk::Automation::Rule.count", "Desk::Automation::Condition.count",
"Desk::Automation::Action.count"] do
      Desk::Automation::ReorderRulesService.new(@organization, good_payload).process
    end
    assert_equal 3, @rule_1.reload.display_order
    assert_equal 2, @rule_2.reload.display_order
    assert_equal 1, @rule_3.reload.display_order
  end

  private

    def good_payload
      {
        rules: [
          {
            id: @rule_1.id,
            display_order: 3
          },
          {
            id: @rule_2.id,
            display_order: 2
          },
          {
            id: @rule_3.id,
            display_order: 1
          }
        ]
      }
    end
end
