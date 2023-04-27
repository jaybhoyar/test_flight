# frozen_string_literal: true

require "test_helper"

module Desk
  class BusinessHours::HolidayTest < ActiveSupport::TestCase
    setup do
      @business_hour = create :business_hour
    end

    test "name should not be blank" do
      holiday = build :holiday, name: nil, date: Date.current, business_hour: @business_hour
      assert_not holiday.valid?
      assert holiday.errors.added?(:name, "can't be blank")
    end

    test "start date should not be blank" do
      holiday = build :holiday, date: nil, name: Faker::Name.name, business_hour: @business_hour
      assert_not holiday.valid?
      assert holiday.errors.added?(:date, "can't be blank")
    end

    test "should not be valid without business hour" do
      holiday = build(:holiday, business_hour: nil)
      assert_not holiday.valid?
    end

    test "should save data with valid details" do
      assert_difference "Desk::BusinessHours::Holiday.count", 1 do
        create :holiday
      end
    end
  end
end
