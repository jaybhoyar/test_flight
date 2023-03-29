# frozen_string_literal: true

class Desk::Reports::DateRangeService
  attr_reader :args, :start_date, :end_date, :errors

  PredefinedRangeNames = [
    "last_7_days",
    "last_30_days",
    "this_month",
    "last_month",
    "this_quarter",
    "last_quarter",
    "this_week",
    "last_week"
  ]

  def initialize(args)
    @args = args || {}
    @errors = []
    @my_present_day = args[:present_day]
  end

  def process
    process_date_range_parameters
  end

  def valid_params?
    validate_date_range_parameters
  end

  def number_of_days
    (@end_date.to_date - @start_date.to_date).to_i
  end

  private

    def present_day
      @my_present_day || Time.zone.now
    end

    def process_date_range_parameters
      if predefined_date_range?
        process_predefined_date_range_parameters(@args[:name])
      else
        process_custom_date_range_parameters(@args[:from], @args[:to])
      end
    end

    def process_predefined_date_range_parameters(date_range_name)
      @start_date, @end_date = send(date_range_name)
    end

    def process_custom_date_range_parameters(from, to)
      @start_date = parse_time(from).beginning_of_day
      @end_date = parse_time(to).end_of_day
    end

    def validate_date_range_parameters
      if predefined_date_range?
        valid_predefined_date_range_parameters?(@args[:name])
      else
        valid_custom_date_range_parameters?(@args[:from], @args[:to])
      end
    end

    def predefined_date_range?
      @args[:type] == "predefined"
    end

    def valid_predefined_date_range_parameters?(date_range_name)
      unless valid_predefined_date_range_keys.include?(date_range_name)
        @errors << "'#{date_range_name}' is not a valid 'name'."
        return false
      end

      true
    end

    def valid_custom_date_range_parameters?(from, to)
      if from.nil?
        @errors << "'from' is required."
        return false
      end

      if to.nil?
        @errors << "'to' is required."
        return false
      end

      begin
        from_obj = parse_date(from)
      rescue
        @errors << "'from' is not valid. Use 'YYYY-MM-DD' format."
        return false
      end

      begin
        to_obj = parse_date(to)
      rescue
        @errors << "'to' is not valid. Use 'YYYY-MM-DD' format."
        return false
      end

      if from_obj > to_obj
        @errors << "'from' should be less than or equal to 'to'."
        return false
      end

      true
    end

    def valid_predefined_date_range_keys
      @_valid_predefined_date_range_keys ||= PredefinedRangeNames
    end

    def parse_date(date_string)
      parse_time(date_string).to_date
    end

    def parse_time(date_string)
      Time.zone.parse(date_string)
    end

    def last_7_days
      today = present_day.to_date

      [(today + 1 - 7).beginning_of_day, today.end_of_day]
    end

    def last_30_days
      today = present_day.to_date

      [(today + 1 - 30).beginning_of_day, today.end_of_day]
    end

    def this_week
      now = present_day

      [now.beginning_of_week, now.end_of_week]
    end

    def last_week
      now_last_week = present_day.last_week

      [now_last_week.beginning_of_week, now_last_week.end_of_week]
    end

    def this_month
      now = present_day

      [now.beginning_of_month, now.end_of_month]
    end

    def last_month
      now_last_month = present_day.last_month

      [now_last_month.beginning_of_month, now_last_month.end_of_month]
    end

    def this_quarter
      now = present_day

      [now.beginning_of_quarter, now.end_of_quarter]
    end

    def last_quarter
      now_last_quarter = present_day.last_quarter

      [now_last_quarter.beginning_of_quarter, now_last_quarter.end_of_quarter]
    end
end
