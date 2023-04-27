# frozen_string_literal: true

require "test_helper"
require "policy_assertions"

class UserPolicyTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization

    @user = create :user, organization: @organization
    @admin = create :user_with_admin_role, organization: @organization
    @agent = create :user_with_agent_role, organization: @organization
    @customer = create :user, organization: @organization, role: nil

    @manage_permission = Permission.find_or_create_by(name: "agents.manage_agent_details", category: "Agents")
    role = create :organization_role_admin, permissions: [@manage_permission]
    @admin.update(role:)
  end

  def test_only_user_with_permissions_can_verify
    assert_policy(@admin, @user, :can_verify?)
    refute_policy(@agent, @user, :can_verify?)

    refute_policy(@customer, @user, :can_verify?)
  end
end
