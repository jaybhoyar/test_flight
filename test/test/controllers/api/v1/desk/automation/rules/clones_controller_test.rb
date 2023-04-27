# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Automation::Rules::ClonesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)
    @manage_permission = Permission.find_or_create_by(name: "admin.manage_automation_rules", category: "Admin")
    role = create :organization_role, permissions: [@manage_permission]
    @user.update(role:)
  end

  def test_that_rule_is_cloned
    @rule = create :automation_rule_with_data, name: "Billing", organization: @organization

    assert_difference "Desk::Automation::Rule.count" do
      post api_v1_desk_automation_rule_clone_url(@rule.id), headers: headers(@user)
    end
    assert_response :ok
    assert_not_nil json_body["rule"]
    assert_equal "Rule has been successfully cloned.", json_body["notice"]
  end

  def test_that_clone_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    @rule = create :automation_rule_with_data, name: "Billing", organization: @organization

    post api_v1_desk_automation_rule_clone_url(@rule.id), headers: headers(@user)
    assert_response :forbidden
  end
end
