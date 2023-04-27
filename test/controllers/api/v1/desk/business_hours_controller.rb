# frozen_string_literal: true

class Api::V1::Desk::BusinessHoursController < Api::V1::BaseController
  before_action :fetch_time_zones, only: [:new, :edit]
  before_action :load_business_hour!, only: [:show, :edit, :update, :destroy]
  before_action :load_business_hours!, only: :destroy_multiple

  def new
    @business_hour = Desk::BusinessHours::CreationService.new.process
  end

  def index
    @business_hours = @organization.business_hours.order(sort_by)
    @total_count = @business_hours.size

    if search?
      @business_hours = @business_hours.where("name ILIKE ?", "%#{params[:business_hour][:search_term]}%")
    end

    if paginate?
      @business_hours = @business_hours.page(page_index).per(per_page)
    end
  end

  def create
    business_hour = @organization.business_hours.new(business_hour_params)
    if business_hour.save
      render json: { success: true }, status: :ok
    else
      render json: { errors: business_hour.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    render
  end

  def edit
    render
  end

  def update
    if @business_hour.update(business_hour_params)
      render json: { notice: "Business hour has been successfully updated." }, status: :ok
    else
      render json: {
        errors: @business_hour.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    service = Desk::BusinessHours::DeletionService.new([@business_hour])
    service.process

    if service.success?
      render json: { notice: service.response }, status: :ok
    else
      render json: { error: service.errors }, status: :unprocessable_entity
    end
  end

  def destroy_multiple
    service = Desk::BusinessHours::DeletionService.new(@business_hours)
    service.process

    if service.success?
      render json: { notice: service.response }, status: :ok
    else
      render json: { error: service.errors }, status: :unprocessable_entity
    end
  end

  private

    def load_business_hour!
      @business_hour = @organization.business_hours.find_by!(id: params[:id])
    end

    def load_business_hours!
      @business_hours = @organization.business_hours.where!(id: params[:business_hour][:ids])
    end

    def search?
      params[:business_hour] && params[:business_hour][:search_term].present?
    end

    def fetch_time_zones
      @time_zone_carrier = TimeZoneCarrier.new
    end

    def business_hour_params
      return {} unless params[:business_hour].present?

      params.require(:business_hour).permit(
        :id, :name, :description, :time_zone,
        holidays_attributes: [:id, :name, :date, :_destroy],
        schedules_attributes: [:id, :day, :status, :from, :to, :_destroy]
      )
    end

    def paginate?
      params[:business_hour] && params[:business_hour][:page_index].present?
    end

    def per_page
      params[:business_hour][:page_size] || 15
    end

    def page_index
      params[:business_hour][:page_index] || 1
    end

    def sort_by
      if params[:business_hour].present?
        column = params[:business_hour][:column] || "name"
        direction = params[:business_hour][:direction] || "asc"

        { column => direction }
      end
    end
end
