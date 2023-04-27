# frozen_string_literal: true

require "test_helper"

class RecordVisibilityTest < ActiveSupport::TestCase
  def test_valid_record_visibility
    record_visibility = create(:record_visibility)

    assert record_visibility.valid?
  end

  def test_that_record_is_valid_without_creator
    record_visibility = build :record_visibility, creator: nil

    assert record_visibility.valid?
  end

  def test_invalid_record_visibility
    record_visibility = RecordVisibility.new

    assert_not record_visibility.valid?
    assert_includes record_visibility.errors.full_messages, "Record must exist"
    assert_includes record_visibility.errors.full_messages, "Visibility can't be blank"
  end

  def test_invalid_record_visibility_when_assigned_invalid_visibility
    assert_raises ArgumentError do
      record_visibility = RecordVisibility.new
      record_visibility.visibility = "invalid"
    end
  end
end
