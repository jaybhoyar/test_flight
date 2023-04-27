# frozen_string_literal: true

module DateRangeSelectable
  extend ActiveSupport::Concern

  def setup_date_range
    date_range_service = Desk::Reports::DateRangeService.new(params[:date_range])

    unless date_range_service.valid_params?
      render json: { errors: date_range_service.errors }, status: 400
      return false
    end

    date_range_service.process

    previous_date_range_service = Desk::Reports::PreviousPeriodDateRangeService.new(params[:date_range])
    previous_date_range_service.process

    @start_date = date_range_service.start_date
    @end_date = date_range_service.end_date

    @previous_start_date = previous_date_range_service.start_date
    @previous_end_date = previous_date_range_service.end_date
  end
end
