# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Automation::ReorderRulesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    @rule_1 = create :automation_rule_with_data, name: "Rule 1", organization: @organization
    @rule_2 = create :automation_rule_with_data, name: "Rule 2", organization: @organization
    @rule_3 = create :automation_rule_with_data, name: "Rule 3", organization: @organization

    host! test_domain(@organization.subdomain)
    @manage_permission = Permission.find_or_create_by(name: "admin.manage_automation_rules", category: "Admin")
    role = create :organization_role, permissions: [@manage_permission]
    @user.update(role:)
  end

  def test_that_rules_are_reordered
    assert_no_difference ["Desk::Automation::Rule.count", "Desk::Core::Condition.count",
"Desk::Automation::Action.count"] do
      patch api_v1_desk_automation_reorder_rules_url(good_payload), headers: headers(@user)
    end
    assert_response :ok
    assert_equal 3, @rule_1.reload.display_order
    assert_equal 2, @rule_2.reload.display_order
    assert_equal 1, @rule_3.reload.display_order
  end

  def test_that_reorder_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    patch api_v1_desk_automation_reorder_rules_url(good_payload), headers: headers(@user)
    assert_response :forbidden
  end

  private

    def good_payload
      {
        reorder_rule: {
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
      }
    end
end
