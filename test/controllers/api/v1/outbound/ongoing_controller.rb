# frozen_string_literal: true

class Api::V1::Outbound::OngoingController < Api::V1::BaseController
  def index
    load_ongoing_messages
  end

  def destroy_multiple
    deletion_service = Desk::Outbound::MessageDeletionService.new(params[:message_ids])
    deletion_service.process

    if deletion_service.success?
      load_ongoing_messages
      render :index, status: :ok
    else
      render json: deletion_service.response, status: :unprocessable_entity
    end
  end

  private

    def load_ongoing_messages
      messages = @organization.outbound_messages.ongoing.includes(:latest_message_event)

      if params[:search_string]
        messages = messages.where("title ILIKE ?", "%#{params[:search_string]}%")
      end

      @ongoing_count = messages.count

      messages = messages.page(page_index).per(page_limit)

      @outbound_messages_carriers = messages.map do |ongoing_message|
        Outbound::MessageCarrier.new(ongoing_message)
      end
    end

    def page_index
      params[:page] || 1
    end

    def page_limit
      params[:per_page] || 15
    end
end
