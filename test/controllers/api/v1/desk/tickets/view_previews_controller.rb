# frozen_string_literal: true

class Api::V1::Desk::Tickets::ViewPreviewsController < Api::V1::BaseController
  def create
    service = Desk::Views::RulePreviewService.new(@organization, rule_params)

    if service.valid_conditions?
      @tickets = service.matching_tickets.includes(:agent, :requester, :group).page(1).per(5)
      render "/api/v1/desk/tickets/index"
    else
      render json: { errors: service.error_messages }, status: :unprocessable_entity
    end
  end

  private

    def rule_params
      params.require(:rule).permit(
        conditions_attributes: [:join_type, :field, :verb, :value, :kind, tag_ids: []]
      )
    end
end
