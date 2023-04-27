# frozen_string_literal: true

class Api::V1::Desk::AgentsController < Api::V1::BaseController
  def index
    @agents = Desk::Agents::FilterService.new(agents.includes(:groups), agent_filter_params).process
  end

  private

    def agent_filter_params
      return {} unless params.has_key?(:filters)

      params.permit(filters: [:search_string])
    end

    def agents
      @organization.users.available.with_permissions(*allowed_permissions)
    end

    def allowed_permissions
      ["desk.manage_own_tickets", "desk.reply_add_note_to_tickets", "desk.manage_tickets"]
    end
end
