# frozen_string_literal: true

require "test_helper"
class Desk::Reports::PreviousPeriodDateRangeServiceTest < ActiveSupport::TestCase
  def setup
    travel_to Time.zone.parse("2020-04-16 20:52:13")
  end

  def teardown
    travel_back
  end

  def test_process_with_custom_date_range
    date_range_params = { type: "custom", from: "2019-01-30", to: "2019-03-05" }

    date_range_service = Desk::Reports::PreviousPeriodDateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2018-12-26", date_range_service.start_date.to_date.to_s
    assert_equal "2019-01-29", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_last_7_days
    date_range_params = { type: "predefined", name: "last_7_days" }

    date_range_service = Desk::Reports::PreviousPeriodDateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-04-03", date_range_service.start_date.to_date.to_s
    assert_equal "2020-04-09", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_last_30_days
    date_range_params = { type: "predefined", name: "last_30_days" }

    date_range_service = Desk::Reports::PreviousPeriodDateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-02-17", date_range_service.start_date.to_date.to_s
    assert_equal "2020-03-17", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_this_week
    date_range_params = { type: "predefined", name: "this_week" }

    date_range_service = Desk::Reports::PreviousPeriodDateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-04-06", date_range_service.start_date.to_date.to_s
    assert_equal "2020-04-12", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_last_week
    date_range_params = { type: "predefined", name: "last_week" }

    date_range_service = Desk::Reports::PreviousPeriodDateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-03-30", date_range_service.start_date.to_date.to_s
    assert_equal "2020-04-05", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_this_month
    date_range_params = { type: "predefined", name: "this_month" }

    date_range_service = Desk::Reports::PreviousPeriodDateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-03-01", date_range_service.start_date.to_date.to_s
    assert_equal "2020-03-31", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_last_month
    date_range_params = { type: "predefined", name: "last_month" }

    date_range_service = Desk::Reports::PreviousPeriodDateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-02-01", date_range_service.start_date.to_date.to_s
    assert_equal "2020-02-29", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_this_quarter
    date_range_params = { type: "predefined", name: "this_quarter" }

    date_range_service = Desk::Reports::PreviousPeriodDateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2020-01-01", date_range_service.start_date.to_date.to_s
    assert_equal "2020-03-31", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end

  def test_process_with_predefined_date_range_last_quarter
    date_range_params = { type: "predefined", name: "last_quarter" }

    date_range_service = Desk::Reports::PreviousPeriodDateRangeService.new(date_range_params)
    date_range_service.process

    assert_equal "2019-10-01", date_range_service.start_date.to_date.to_s
    assert_equal "2019-12-31", date_range_service.end_date.to_date.to_s

    assert_includes date_range_service.start_date.to_s, "00:00:00"
    assert_includes date_range_service.end_date.to_s, "23:59:59"
  end
end
