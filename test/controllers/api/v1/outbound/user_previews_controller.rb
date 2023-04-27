# frozen_string_literal: true

class Api::V1::Outbound::UserPreviewsController < Api::V1::BaseController
  def create
    service = Desk::Outbound::RulePreviewService.new(@organization, rule_params)

    if service.valid_conditions?
      @customers = service.matching_users
      if future_users_condition?
        @customers = nil
      end
      render "/api/v1/outbound/user_previews/index"
    else
      render json: { errors: service.error_messages }, status: :unprocessable_entity
    end
  end

  private

    def rule_params
      params.require(:rule).permit(
        conditions_attributes: [:join_type, :field, :verb, :value]
      )
    end

    def future_users_condition?
      rule_params[:conditions_attributes].each do |condition|
        if condition[:field] == "created_at" && condition[:verb] == "greater_than"
          return true
        end
      end
      false
    end
end
