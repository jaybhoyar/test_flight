# frozen_string_literal: true

require "test_helper"

class ActivityCarrierTest < ActiveSupport::TestCase
  def setup
    @activity_1 = create :activity
    rule = create :automation_rule, name: "Automatically assign refund tag"
    @activity_2 = create :activity, owner: rule
  end

  def test_system_activity
    assert_not ActivityCarrier.new(@activity_1).system_activity?

    assert ActivityCarrier.new(@activity_2).system_activity?
  end

  def test_owner_name
    assert_equal @activity_1.owner.name, ActivityCarrier.new(@activity_1).owner_name

    assert_equal "Automation Rule", ActivityCarrier.new(@activity_2).owner_name
  end

  def test_does_not_fail_when_activity_owner_is_nil
    @activity_1.owner = nil

    assert_nil @activity_1.owner
  end

  def test_system_activity_details
    assert_equal({}, ActivityCarrier.new(@activity_1).system_activity_details)

    assert_equal "Automatically assign refund tag", ActivityCarrier.new(@activity_2).system_activity_details[:name]
  end

  def test_that_error_is_not_raised_for_deleted_rule
    @activity_2.owner.destroy

    assert_equal "Automation Rule", ActivityCarrier.new(@activity_2).system_activity_details[:name]
  end
end
