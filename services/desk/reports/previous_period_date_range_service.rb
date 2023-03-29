# frozen_string_literal: true

module Desk::Reports
  class PreviousPeriodDateRangeService
    attr_reader :start_date, :end_date

    def initialize(args)
      @args = args

      @current_date_range_service = DateRangeService.new(@args)
      @current_date_range_service.process
    end

    def process
      unless predefined_date_range?
        @end_date = @current_date_range_service.start_date.yesterday.end_of_day
        @start_date = (@end_date.to_date - @current_date_range_service.number_of_days).beginning_of_day
      else
        date_range_service = DateRangeService.new(@args.merge(present_day: previous_period_present_day))
        date_range_service.process

        @start_date = date_range_service.start_date
        @end_date = date_range_service.end_date
      end
    end

    private

      def previous_period_present_day
        case @args[:name]
        when "this_week"
          today.last_week
        when "last_week"
          today.last_week
        when "this_month"
          today.last_month
        when "last_month"
          today.last_month
        when "this_quarter"
          today.last_quarter
        when "last_quarter"
          today.last_quarter
        else
          @current_date_range_service.start_date.to_date.yesterday.end_of_day
        end
      end

      def today
        Time.zone.now
      end

      def predefined_date_range?
        @args[:type] == "predefined"
      end
  end
end
