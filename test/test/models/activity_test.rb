# frozen_string_literal: true

require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  test "valid activity" do
    activity = create(:activity)

    assert activity.valid?
  end

  test "invalid activity" do
    activity = Activity.new

    assert_not activity.valid?
    assert_includes activity.errors.full_messages, "Action can't be blank"
    assert_includes activity.errors.full_messages, "Trackable must exist"
    assert_includes activity.errors.full_messages, "Key can't be blank"
  end
end
