# frozen_string_literal: true

require "test_helper"

class GroupMemberTest < ActiveSupport::TestCase
  test "valid group_member" do
    group_member = create(:group_member)

    assert group_member.valid?
  end

  test "invalid group_member" do
    group_member = GroupMember.new
    expected_errors = ["User must exist", "Group must exist"]

    assert_not group_member.valid?
    assert_equal expected_errors, group_member.errors.full_messages
  end

  test "duplicate group and user combination is not allowed" do
    group = create(:group)
    user = create(:user)
    group_member1 = create(:group_member, group:, user:)

    group_member2 = GroupMember.new(group:, user:)

    assert_not group_member2.valid?
    assert_equal ["User already belongs to this group."], group_member2.errors.full_messages
  end
end
