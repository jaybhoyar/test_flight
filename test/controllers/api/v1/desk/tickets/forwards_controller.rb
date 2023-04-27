# frozen_string_literal: true

class Api::V1::Desk::Tickets::ForwardsController < Api::V1::BaseController
  before_action :load_ticket!, only: [:create]

  def create
    @comment = process_ticket_forward

    if @comment.valid?
      render
    else
      render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def forward_ticket_params
      params.require(:forward_ticket).permit(
        :forward_text,
        attachments: [],
        forward_emails_attributes: [:email, :delivery_type]
      )
    end

    def process_ticket_forward
      ticket_forward_service = Desk::Ticketing::ForwardTicketService.new(
        @ticket,
        forward_ticket_params[:forward_text],
        forward_ticket_params[:forward_emails_attributes],
        forward_ticket_params[:attachments],
        current_user
      )

      begin
        ticket_forward_service.process
      rescue ActiveRecord::RecordInvalid => invalid
        invalid.record
      end
    end

    def load_ticket!
      @ticket = @organization.tickets.find_by!(id: params[:ticket_id])
    end
end
