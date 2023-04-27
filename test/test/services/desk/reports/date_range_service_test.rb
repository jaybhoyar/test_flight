# frozen_string_literal: true

require "test_helper"
class Desk::Reports::DateRangeServiceTest < ActiveSupport::TestCase
  def setup
    travel_to Time.zone.parse("2020-04-16 20:52:13")
  end

  def teardown
    travel_back
  end

  def test_valid_predefined_date_range
    date_range_params = { type: "predefined", name: "last_7_days" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    assert date_range_service.valid_params?
  end

  def test_valid_custom_date_range_from_less_than_to
    date_range_params = { type: "custom", from: "2019-10-20", to: "2019-12-31" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    assert date_range_service.valid_params?
  end

  def test_valid_custom_date_range_from_equal_to_two
    date_range_params = { type: "custom", from: "2019-10-20", to: "2019-10-20" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    assert date_range_service.valid_params?
  end

  def test_invalid_predefined_date_range
    date_range_params = { type: "predefined", name: "last_27_days" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    assert_not date_range_service.valid_params?
    assert_equal "'last_27_days' is not a valid 'name'.", date_range_service.errors.first
  end

  def test_invalid_custom_date_range_case_1
    date_range_params = { type: "custom" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    assert_not date_range_service.valid_params?
    assert_equal "'from' is required.", date_range_service.errors.first
  end

  def test_invalid_custom_date_range_case_2
    date_range_params = { type: "custom", from: "2019-10-15" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    assert_not date_range_service.valid_params?
    assert_equal "'to' is required.", date_range_service.errors.first
  end

  def test_invalid_custom_date_range_from_greater_than_to
    date_range_params = { type: "custom", from: "2019-10-15", to: "2018-10-15" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    assert_not date_range_service.valid_params?
    assert_equal "'from' should be less than or equal to 'to'.", date_range_service.errors.first
  end

  def test_process_with_custom_date_range
    date_range_params = { type: "custom", from: "2019-01-01", to: "2020-03-31" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2019-01-01", date_range_service.start_date.to_date.to_s
    assert_equal "2020-03-31", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_last_7_days
    date_range_params = { type: "predefined", name: "last_7_days" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-04-10", date_range_service.start_date.to_date.to_s
    assert_equal "2020-04-16", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_last_30_days
    date_range_params = { type: "predefined", name: "last_30_days" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-03-18", date_range_service.start_date.to_date.to_s
    assert_equal "2020-04-16", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_this_week
    date_range_params = { type: "predefined", name: "this_week" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-04-13", date_range_service.start_date.to_date.to_s
    assert_equal "2020-04-19", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_last_week
    date_range_params = { type: "predefined", name: "last_week" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-04-06", date_range_service.start_date.to_date.to_s
    assert_equal "2020-04-12", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_this_month
    date_range_params = { type: "predefined", name: "this_month" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-04-01", date_range_service.start_date.to_date.to_s
    assert_equal "2020-04-30", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_last_month
    date_range_params = { type: "predefined", name: "last_month" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-03-01", date_range_service.start_date.to_date.to_s
    assert_equal "2020-03-31", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_this_quarter
    date_range_params = { type: "predefined", name: "this_quarter" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-04-01", date_range_service.start_date.to_date.to_s
    assert_equal "2020-06-30", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_last_quarter
    date_range_params = { type: "predefined", name: "last_quarter" }

    date_range_service = Desk::Reports::DateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-01-01", date_range_service.start_date.to_date.to_s
    assert_equal "2020-03-31", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end
end
