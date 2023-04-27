# frozen_string_literal: true

class Api::V1::Desk::Automation::RulePreviewsController < Api::V1::BaseController
  before_action :ensure_access_to_manage_automation_rules!

  def create
    service = init_preview_service
    page_index = request.query_parameters["page_index"]
    if service.valid_conditions?
      @tickets = service.matching_tickets
        .includes(:agent, :requester, :group)
        .order(created_at: :desc)
        .page(page_index || 1).per(5)

      render "/api/v1/desk/tickets/index"
    else
      render json: { errors: service.error_messages }, status: :unprocessable_entity
    end
  end

  private

    def rule_params
      params.require(:rule).permit(
        condition_groups_attributes: [
          :join_type, :conditions_join_type, :_destroy,
          conditions_attributes: [
            :join_type, :field, :verb, :value, :kind, :_destroy, tag_ids: []
          ]
        ],
      )
    end

    def init_preview_service
      Desk::Automation::RulePreviewService.new(@organization, rule_params)
    end
end
