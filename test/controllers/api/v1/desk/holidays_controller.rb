# frozen_string_literal: true

class Api::V1::Desk::HolidaysController < Api::V1::BaseController
  before_action :load_business_hour!
  before_action :load_holiday!, only: [:destroy, :update]

  def index
    @holidays = @business_hour.holidays.order(:date)
  end

  def create
    holiday = @business_hour.holidays.new(holiday_params)
    if holiday.save
      render status: :ok, json: { success: true, notice: "Holiday has been successfully created." }
    else
      render status: :unprocessable_entity, json: { errors: holiday.errors.full_messages }
    end
  end

  def update
    if @holiday.update(holiday_params)
      render json: { notice: "Holiday has been successfully updated." }, status: :ok
    else
      render json: { errors: @holiday.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @holiday.destroy
      render json: { notice: "Holiday has been successfully removed." }, status: :ok
    else
      render json: { errors: @holiday.errors.full_messages }, status: :not_found
    end
  end

  private

    def load_business_hour!
      @business_hour = @organization.business_hours.find_by!(id: params[:business_hour_id])
    end

    def load_holiday!
      @holiday = @business_hour.holidays.find_by!(id: params[:id])
    end

    def holiday_params
      params.require(:holiday).permit(:name, :date)
    end
end
