# frozen_string_literal: true

require "test_helper"

class GroupTest < ActiveSupport::TestCase
  test "valid group" do
    group = create(:group)

    assert group.valid?
  end

  test "business hour should be optional for group" do
    group = create(:group, business_hour: nil)
    assert group.valid?
  end

  test "invalid group" do
    group = Group.new
    expected_errors = ["Organization must exist", "Name can't be blank"]

    assert_not group.valid?
    assert_equal expected_errors, group.errors.full_messages
  end

  test "duplicate group name for same organization is not allowed" do
    organization = create(:organization)
    group1 = create(:group, name: "Sales", organization:)

    group2 = Group.new(organization:, name: "Sales")

    assert_not group2.valid?
    assert_equal ["Name has already been taken"], group2.errors.full_messages
  end

  test "duplicate group name for different organization is accepted" do
    organization1 = create(:organization)
    organization2 = create(:organization)
    group1 = create(:group, name: "Sales", organization: organization1)

    group2 = Group.new(organization: organization2, name: "Sales")

    assert group2.valid?
    assert_empty group2.errors.full_messages
  end

  def test_that_group_cannot_be_deleted_having_reference_with_macro_action
    group = create :group

    create :desk_macro_action, name: "assign_group", actionable: group

    assert_no_difference "Group.count" do
      group.destroy
    end

    assert_includes group.errors.full_messages.first, "This team is used in Views, Automation Rules, or Canned Responses"
  end

  def test_that_group_cannot_be_deleted_having_reference_with_automation_action
    group = create :group

    create :automation_action, name: "assign_group", actionable: group

    assert_no_difference "Group.count" do
      group.destroy
    end

    assert_includes group.errors.full_messages.first, "This team is used in Views, Automation Rules, or Canned Responses"
  end

  def test_that_group_cannot_be_deleted_having_reference_with_automation_condition
    group = create :group

    create :automation_condition, field: "group_id", value: group.id

    assert_no_difference "Group.count" do
      group.destroy
    end

    assert_includes group.errors.full_messages.first, "This team is used in Views, Automation Rules, or Canned Responses"
  end
end
