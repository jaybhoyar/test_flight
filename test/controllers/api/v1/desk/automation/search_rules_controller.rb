# frozen_string_literal: true

class Api::V1::Desk::Automation::SearchRulesController < Api::V1::BaseController
  def show
    @rules = service.search
    @total_count = @rules.count
    render "/api/v1/desk/automation/rules/index"
  end

  private

    def search_params
      params.permit(:term)
    end

    def service
      Desk::Automation::Rules::SearchService.new(@organization, search_params[:term])
    end
end
