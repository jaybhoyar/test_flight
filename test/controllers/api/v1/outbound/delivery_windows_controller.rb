# frozen_string_literal: true

class Api::V1::Outbound::DeliveryWindowsController < Api::V1::BaseController
  before_action :fetch_time_zones, only: [:new, :edit]
  before_action :load_outbound_message, only: [:new, :index, :create, :edit, :update, :destroy]
  before_action :load_outbound_delivery_window, only: [:edit, :update, :destroy]

  def new
    @outbound_delivery_window = Desk::Outbound::DeliveryWindowService.new.process
  end

  def index
    @outbound_delivery_windows = @outbound_message.delivery_windows.order(:created_at)
  end

  def create
    outbound_delivery_window = @outbound_message.delivery_windows.new(outbound_delivery_window_params)
    if outbound_delivery_window.save
      render status: :ok, json: { notice: "Delivery window has been successfully added." }
    else
      render json: { errors: outbound_delivery_window.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def edit
    render
  end

  def update
    if @outbound_delivery_window.update(outbound_delivery_window_params)
      render status: :ok, json: { notice: "Delivery window has been successfully updated." }
    else
      render json: { errors: @outbound_delivery_window.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @outbound_delivery_window.destroy
      render status: :ok, json: { notice: "Delivery window has been successfully deleted." }
    else
      render json: { errors: @outbound_delivery_window.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def outbound_delivery_window_params
      params.require(:delivery_window).permit(
        :id, :name, :time_zone,
        schedules_attributes: [:id, :day, :status, :from, :to])
    end

    def load_outbound_message
      @outbound_message = Outbound::Message.find(params[:message_id])
    end

    def fetch_time_zones
      @time_zone_carrier = TimeZoneCarrier.new
    end

    def load_outbound_delivery_window
      @outbound_delivery_window = @outbound_message.delivery_windows.find_by(id: params[:id])
    end
end
