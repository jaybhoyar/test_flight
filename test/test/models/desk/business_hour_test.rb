# frozen_string_literal: true

require "test_helper"

module Desk
  class BusinessHourTest < ActiveSupport::TestCase
    def test_name_should_not_be_blank
      @organization = create :organization
      business_hour = build :business_hour, name: "", organization: @organization

      assert_not business_hour.valid?
      assert business_hour.errors.added?(:name, "should not be blank")
    end

    def test_should_not_have_duplicate_names
      @organization = create :organization
      business_hour = create :business_hour, organization: @organization
      business_hour_dup = build :business_hour, organization: @organization
      assert_not business_hour_dup.valid?
      assert business_hour_dup.errors.added?(:name, "has already been taken")
    end

    def test_should_not_be_valid_without_organization
      business_hour = build :business_hour, organization: nil
      assert_not business_hour.valid?
    end

    def test_should_not_be_valid_without_time_zone
      business_hour = build :business_hour, time_zone: nil
      assert_not business_hour.valid?
    end

    def test_remove_all_groups
      business_hour = create :business_hour
      group = create :group, business_hour: business_hour

      assert_equal 1, business_hour.groups.count
      business_hour.remove_all_groups!
      assert_equal 0, business_hour.reload.groups.count
    end
  end
end
