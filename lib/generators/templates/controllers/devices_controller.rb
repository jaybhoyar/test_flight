# frozen_string_literal: true

class Api::V1::DevicesController < Api::V1::BaseController
  before_action :load_device!, only: [:destroy]

  def create
    device = current_user.devices.new(device_params)

    if device.save
      render status: :ok, json: { notice: 'Device has been registered successfully.', device: device }
    else
      render status: :unprocessable_entity, json: { errors: device.errors.full_messages }
    end
  end

  def destroy
    if @device.destroy
      render json: { notice: 'Device has been removed successfully' }, status: :ok
    else
      render json: { errors: @device.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def device_params
      params.require(:device).permit(:device_token, :platform)
    end

    def load_device!
      @device = Device.find_by!(id: params[:id])
    end
end
