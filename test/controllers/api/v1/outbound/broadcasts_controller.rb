# frozen_string_literal: true

class Api::V1::Outbound::BroadcastsController < Api::V1::BaseController
  def index
    load_broadcast_messages
  end

  def destroy_multiple
    deletion_service = Desk::Outbound::MessageDeletionService.new(params[:message_ids])
    deletion_service.process

    if deletion_service.success?
      load_broadcast_messages
      render :index, status: :ok
    else
      render json: deletion_service.response, status: :unprocessable_entity
    end
  end

  private

    def load_broadcast_messages
      messages = @organization.outbound_messages.includes(:latest_message_event).broadcast

      if params[:search_string]
        messages = messages.where("title ILIKE ?", "%#{params[:search_string]}%")
      end

      @broadcasts_count = messages.count

      messages = messages.page(page_index).per(page_limit)

      @outbound_messages_carriers = messages.map do |broadcast_message|
        Outbound::MessageCarrier.new(broadcast_message)
      end
    end

    def page_index
      params[:page] || 1
    end

    def page_limit
      params[:per_page] || 15
    end
end
