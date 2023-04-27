# frozen_string_literal: true

class Api::V1::Desk::Automation::ReorderRulesController < Api::V1::BaseController
  before_action :ensure_access_to_manage_automation_rules!

  def update
    service = init_reorder_service
    service.process

    render json: service.response, status: service.status
  end

  private

    def reorder_params
      params.require(:reorder_rule).permit(rules: [:id, :display_order])
    end

    def init_reorder_service
      Desk::Automation::ReorderRulesService.new(@organization, reorder_params)
    end
end
