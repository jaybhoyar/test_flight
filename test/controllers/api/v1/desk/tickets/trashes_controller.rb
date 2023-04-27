# frozen_string_literal: true

class Api::V1::Desk::Tickets::TrashesController < Api::V1::BaseController
  before_action :load_tickets, only: [:update, :destroy]

  def update
    service = Desk::Ticketing::RestoreTicketsService.new(@tickets)
    service.process

    if service.errors.present?
      render status: :unprocessable_entity, json: { error: service.errors }
    else
      render status: :ok, json: { notice: service.response }
    end
  end

  def destroy
    service = Desk::Ticketing::DeleteTicketsService.new(@tickets)
    service.process

    if service.errors.present?
      render status: :unprocessable_entity, json: { error: service.errors }
    else
      render status: :ok, json: { notice: service.response }
    end
  end

  private

    def tickets_params
      params.require(:ticket).permit(ids: [])
    end

    def load_tickets
      @tickets = @organization.tickets.where(id: tickets_params[:ids])
    end
end
