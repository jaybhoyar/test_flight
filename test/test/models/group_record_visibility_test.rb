# frozen_string_literal: true

require "test_helper"

class GroupRecordVisibilityTest < ActiveSupport::TestCase
  def test_valid_group_record_visibility
    group_record_visibility = create(:group_record_visibility)

    assert group_record_visibility.valid?
  end

  def test_invalid_group_record_visibility
    group_record_visibility = GroupRecordVisibility.new

    assert_not group_record_visibility.valid?
    assert_includes group_record_visibility.errors.full_messages, "Group must exist"
    assert_includes group_record_visibility.errors.full_messages, "Record visibility must exist"
  end

  def test_invalid_group_record_visibility_with_duplicate_group
    group = create(:group)
    record_visibility = create(:record_visibility)
    group_record_visibility = create(:group_record_visibility, group:, record_visibility:)
    duplicate_group_record_visibility = build(
      :group_record_visibility, group:,
      record_visibility:)

    assert_not duplicate_group_record_visibility.valid?
    assert_includes duplicate_group_record_visibility.errors.full_messages, "Group already belongs to this record."
  end
end
