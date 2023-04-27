# frozen_string_literal: true

class Api::V1::Public::TicketsController < Api::V1::BaseController
  skip_before_action :authenticate_user_using_x_auth_token, :authenticate_user_for_api
  before_action :authenticate_organization_api_key!

  def create
    @ticket = ticket_creator_service.run

    if @ticket.valid?
      render status: :ok, json: { notice: "Ticket has been successfully submitted." }
    else
      render status: :unprocessable_entity, json: { errors: @ticket.errors.full_messages }
    end
  end

  private

    def ticket_params
      params.permit(:subject, :description, :name, :email, :channel)
    end

    def ticket_creator_service
      Desk::Ticketing::TicketCreatorService.new(
        nil,
        ticket_params[:subject],
        ticket_params[:description],
        @organization,
        nil,
        nil,
        nil,
        customer_name: ticket_params[:name],
        customer_email: ticket_params[:email],
        channel: whitelisted_channel
      )
    end

    def whitelisted_channel
      if ticket_params[:channel].present?
        channel = ticket_params[:channel].downcase
        if Ticket.channels.keys.include? channel
          channel
        end
      end
    end
end
