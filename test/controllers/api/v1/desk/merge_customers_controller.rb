# frozen_string_literal: true

class Api::V1::Desk::MergeCustomersController < Api::V1::BaseController
  before_action :load_customer, only: :create

  def create
    service = Desk::Customers::MergeService.new(@primary_customer, @secondary_customer_ids, @organization)
    service.process

    render service.response
  end

  private

    def merge_params
      params.permit(:primary_customer_id, secondary_customer_ids: [])
    end

    def load_customer
      @primary_customer = @organization.customers.find_by(id: merge_params[:primary_customer_id])
      @secondary_customer_ids = merge_params[:secondary_customer_ids]

      if @primary_customer.nil?
        render json: { error: "Could not find required primary customer." }, status: :not_found
      elsif @secondary_customer_ids.blank?
        render json: { error: "Atleast one secondary customer required." }, status: :unprocessable_entity
      end
    end
end
