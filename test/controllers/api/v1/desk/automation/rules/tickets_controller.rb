# frozen_string_literal: true

class Api::V1::Desk::Automation::Rules::TicketsController < Api::V1::BaseController
  before_action :set_rule, only: [:show]

  def show
    @tickets = @automation_rule.matching_tickets.includes(:agent, :requester, :group).page(1).per(50)
    render "/api/v1/desk/tickets/index"
  end

  private

    def set_rule
      @automation_rule = @organization.rules.find(params[:rule_id])
    end
end
