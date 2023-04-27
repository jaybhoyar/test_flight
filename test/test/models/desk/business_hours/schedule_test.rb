# frozen_string_literal: true

require "test_helper"

module Desk
  class BusinessHours::ScheduleTest < ActiveSupport::TestCase
    def setup
      @business_hour = create(:business_hour)
    end

    test "day should not be blank" do
      @business_hour.schedules.destroy_all
      schedule = @business_hour.schedules.new

      assert_not schedule.valid?
      assert schedule.errors.added?(:day, "should belong to #{Desk::BusinessHours::Schedule::DAYS_NAMES.join(' ')}.")
    end

    test "day should not be other than actual days" do
      schedule = ::Desk::BusinessHours::Schedule.new(day: "Test")

      assert_not schedule.valid?
      assert schedule.errors.added?(:day, "should belong to #{Desk::BusinessHours::Schedule::DAYS_NAMES.join(' ')}.")
    end

    test "from time should be a valid time" do
      schedule = ::Desk::BusinessHours::Schedule.new(
        day: ::Desk::BusinessHours::Schedule::DAYS_NAMES.sample,
        from: "27:00")

      assert_nil schedule.from
    end

    test "to time should be a valid time" do
      schedule = ::Desk::BusinessHours::Schedule.new(
        day: ::Desk::BusinessHours::Schedule::DAYS_NAMES.sample,
        to: "27:00")

      assert_nil schedule.to
    end

    test "from time should be less than to time" do
      schedule = ::Desk::BusinessHours::Schedule.new(
        day: ::Desk::BusinessHours::Schedule::DAYS_NAMES.sample,
        from: "06:00 pm", to: "03:00pm")

      assert_not schedule.valid?
      assert schedule.errors.added?(:from, "time should be less than To time")
    end

    test "status change should work with enum methods" do
      schedule = create(:schedule)
      assert schedule.active?
      assert schedule.inactive!
      assert schedule.inactive?
      assert schedule.active!
    end

    test "should save data with the valid details" do
      @business_hour.schedules.destroy_all
      schedule = @business_hour.schedules.new(
        day: ::Desk::BusinessHours::Schedule::DAYS_NAMES.sample,
        from: "06:00 am", to: "03:00pm", status: "active")

      assert schedule.save
    end
  end
end
