# frozen_string_literal: true

require "test_helper"

class Outbound::DeliveryWindow::ScheduleTest < ActiveSupport::TestCase
  def setup
    travel_to DateTime.parse("6:00 PM")
    @outbound_delivery_window = create(:outbound_delivery_window)
  end

  def teardown
    travel_back
  end

  def test_day_should_not_be_blank
    schedule = @outbound_delivery_window.schedules.new

    assert_not schedule.valid?
    assert_equal ["should belong to #{Outbound::DeliveryWindow::Schedule::DAYS_NAMES.join(' ')}"],
      schedule.errors.messages[:day]
  end

  def test_should_not_be_other_than_actual_days
    schedule = Outbound::DeliveryWindow::Schedule.new(day: "Someday")

    assert_not schedule.valid?
    assert_equal ["should belong to #{Outbound::DeliveryWindow::Schedule::DAYS_NAMES.join(' ')}"],
      schedule.errors.messages[:day]
  end

  def test_from_time_should_be_valid
    schedule = Outbound::DeliveryWindow::Schedule.new(from: "30:00")

    assert_nil schedule.from
  end

  def test_from_time_should_be_less_than_to_time
    schedule = Outbound::DeliveryWindow::Schedule.new(from: "20:00", to: "14:00")

    assert_not schedule.valid?
    assert_equal ["time should be less than To time"], schedule.errors.messages[:from]
  end

  def test_status_change_should_work_with_enum_methods
    schedule = create(:delivery_schedule)
    assert schedule.active?
    assert schedule.inactive!
    assert schedule.inactive?
  end

  def test_active_right_now?
    current_time = DateTime.current
    schedule = create(
      :delivery_schedule, from: current_time - 1.hours, day: current_time.strftime("%A"),
      to: current_time + 2.hours)
    assert schedule.active_right_now?

    schedule = create(
      :delivery_schedule, from: current_time + 1.hours, day: current_time.strftime("%A"),
      to: current_time + 2.hours)
    assert_not schedule.active_right_now?

    schedule = create(
      :delivery_schedule, from: current_time - 5.hours, day: current_time.strftime("%A"),
      to: current_time - 2.hours)
    assert_not schedule.active_right_now?

    schedule = create(
      :delivery_schedule, from: current_time - 5.hours, day: day_other_than_today,
      to: current_time + 2.hours)
    assert_not schedule.active_right_now?
  end

  def day_other_than_today
    day = Outbound::DeliveryWindow::Schedule::DAYS_NAMES.sample

    day == DateTime.current.strftime("%A") ? day_other_than_today : day
  end
end
