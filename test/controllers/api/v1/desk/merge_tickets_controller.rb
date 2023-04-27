# frozen_string_literal: true

class Api::V1::Desk::MergeTicketsController < Api::V1::BaseController
  before_action :load_source_ticket!, only: [:new, :create]
  before_action :ensure_access_to_view_tickets!, only: :show
  before_action :load_ticket, only: :show

  def new
    render
  end

  def create
    service = Desk::Ticketing::MergeService.new(@ticket, current_user, merge_params)
    service.process

    render service.response
  end

  def show
    @user = @ticket.requester
  end

  private

    def merge_params
      params.permit(
        :is_primary_comment_public,
        :is_secondary_comment_public,
        :primary_comment,
        :secondary_comment,
        secondary_ticket_ids: [],
      )
    end

    def load_source_ticket!
      @ticket = @organization.tickets.find_by(number: params[:primary_ticket_number])

      if @ticket.nil?
        render json: { error: "Could not find the ticket." }, status: :not_found
      end
    end

    def load_ticket
      @ticket = @organization.tickets.find_by!(number: params[:id])
      authorize @ticket
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "Could not find the ticket." }, status: :unprocessable_entity
    end
end
