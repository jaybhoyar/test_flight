# frozen_string_literal: true

class Api::V1::Desk::TicketStatusesController < Api::V1::BaseController
  def index
    @statuses = @organization.ticket_statuses
  end
end
