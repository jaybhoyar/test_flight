# frozen_string_literal: true

class Api::V1::Desk::Automation::Rules::ClonesController < Api::V1::BaseController
  before_action :set_rule, only: [:create]
  before_action :ensure_access_to_manage_automation_rules!

  def create
    @rule = clone_rule_service.build_rule

    if @rule.save
      render
    else
      render json: { errors: @rule.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def set_rule
      @automation_rule = @organization.rules.find(params[:rule_id])
    end

    def clone_rule_service
      Desk::Automation::Rules::CloneService.new(@automation_rule)
    end
end
