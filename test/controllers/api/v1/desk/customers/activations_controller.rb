# frozen_string_literal: true

class Api::V1::Desk::Customers::ActivationsController < Api::V1::BaseController
  before_action :load_customer!, only: :create
  before_action :load_customers!, only: :update_multiple
  before_action :ensure_access_to_manage_customer_details!, only: [:create, :update_multiple]

  def create
    if peform_action!
      render json: {
        notice: "#{@customer.first_name}'s account has been #{@customer.active? ? "activated" : "deactivated"}."
      }, status: :ok
    else
      render json: { errors: @customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_multiple
    service = Desk::Customers::ActivationService.new(@customers, activation_params[:status])
    service.process

    if service.success?
      render status: :ok, json: { notice: service.response }
    else
      render status: :unprocessable_entity, json: { error: service.errors }
    end
  end

  private

    def activation_params
      params.require(:customer).permit(:status, :id, :ids)
    end

    def load_customer!
      @customer = User.find_by!(id: activation_params[:id], organization: @organization)
    end

    def load_customers!
      @customers = User
        .includes(:organization)
        .where(id: params[:customer][:ids], organization: @organization)
    end

    def peform_action!
      if activation_params[:status] == "unblock"
        @customer.unblock!
      else
        @customer.block!
      end
    end
end
