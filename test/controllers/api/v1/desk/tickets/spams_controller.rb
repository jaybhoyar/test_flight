# frozen_string_literal: true

class Api::V1::Desk::Tickets::SpamsController < Api::V1::BaseController
  before_action :load_tickets, only: [:update, :destroy]

  def update
    restore_spam_tickets_service = Desk::Ticketing::RestoreTicketsService.new(@tickets)
    restore_spam_tickets_service.process
    if restore_spam_tickets_service.errors.present?
      render status: :unprocessable_entity, json: { error: restore_spam_tickets_service.errors }
    else
      render status: :ok, json: { notice: restore_spam_tickets_service.response }
    end
  end

  def destroy
    delete_spam_tickets_service = Desk::Ticketing::DeleteTicketsService.new(@tickets)
    delete_spam_tickets_service.process
    if delete_spam_tickets_service.errors.present?
      render status: :unprocessable_entity, json: { error: delete_spam_tickets_service.errors }
    else
      render status: :ok, json: { notice: delete_spam_tickets_service.response }
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
