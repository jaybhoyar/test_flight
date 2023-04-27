# frozen_string_literal: true

class Api::V1::Desk::TicketFields::ReordersController < Api::V1::BaseController
  def update
    reorder_service = ticket_fields_reorder_service
    reorder_service.process

    if reorder_service.errors.present?
      render json: { errors: reorder_service.errors }, status: reorder_service.status
    else
      render json: reorder_service.response, status: reorder_service.status
    end
  end

  private

    def field_reorder_params
      params.require(:reorder).permit(fields: [:id, :display_order])
    end

    def ticket_fields_reorder_service
      Desk::Ticket::Fields::ReorderService.new(@organization, field_reorder_params)
    end
end
