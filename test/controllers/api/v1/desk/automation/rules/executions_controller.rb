# frozen_string_literal: true

class Api::V1::Desk::Automation::Rules::ExecutionsController < Api::V1::BaseController
  before_action :set_rule, only: [:create]
  before_action :ensure_access_to_manage_automation_rules!

  def create
    service = execution_service
    service.process

    render json: service.response, status: service.status
  end

  private

    def set_rule
      @automation_rule = @organization.rules.find(params[:rule_id])
    end

    def execution_service
      Desk::Automation::Rules::ExecutionService.new(@automation_rule)
    end
end
