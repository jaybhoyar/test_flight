# frozen_string_literal: true

require "test_helper"

class OrganizationRoleTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
    @ticket_permission = create(:permission, sequence: 1)
    @customer_permissions = create(:customer_view_permissions, sequence: 2)

    @role = create :organization_role, organization: @organization,
      permissions: [@ticket_permission, @customer_permissions]
  end

  test "role_should_be_valid" do
    assert @role.valid?
  end

  test "name should not be blank" do
    role = @organization.roles.new

    assert_not role.valid?
    assert role.errors.added?(:name, "can't be blank")
  end

  test "that name for a system role cannot be changed" do
    @role.name = "Changed Name"
    assert_not @role.valid?
    assert_includes @role.errors.full_messages, "Name for a system role cannot be changed"
  end

  test "that system roles cannot be destroyed" do
    assert_no_difference "@organization.roles.count" do
      @role.destroy
    end
    assert_includes @role.errors.full_messages, "System roles cannot be deleted"
  end

  test "organization_id should be present" do
    role = OrganizationRole.new(name: "Supervisor")

    assert_not role.valid?
    assert role.errors.added?(:organization_id, "can't be blank")
  end

  test "should not create role with duplicate name within the same organization" do
    agent_role = create(:organization_role, permissions: [@ticket_permission])
    organization = agent_role.organization
    agent2_role = organization.roles.new(name: agent_role.name)

    assert_not agent2_role.save
    assert agent2_role.errors.added?(:name, "has already been taken")
  end
end
