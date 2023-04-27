
# frozen_string_literal: true

class Api::V1::Desk::Tickets::TaskActivitiesController < Api::V1::BaseController
  before_action :load_ticket!, only: [:index]

  def index
    @activities = @ticket.task_activities.includes(:owner)
  end

  private

    def load_ticket!
      @ticket = @organization.tickets.find(params[:ticket_id])
    end
end
