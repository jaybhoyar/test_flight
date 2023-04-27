# frozen_string_literal: true

class Api::V1::Outbound::MessagesController < Api::V1::BaseController
  before_action :load_outbound_message!, only: [:show, :update, :send_email, :destroy]

  def index
    outbound_messages = @organization.outbound_messages.includes(:latest_message_event).latest
    @outbound_messages_carriers = outbound_messages.map do |outbound_message|
      Outbound::MessageCarrier.new(outbound_message)
    end
  end

  def create
    @outbound_message = @organization.outbound_messages.new(outbound_message_params)
    if @outbound_message.save
      render json: {
        notice: "Campaign has been successfully added.",
        message_id: @outbound_message.id
      }, status: :ok
    else
      render json: { errors: @outbound_message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    @outbound_message_carrier = Outbound::MessageCarrier.new(@outbound_message)
    render
  end

  def update
    if @outbound_message.update(outbound_message_params)
      render json: { notice: "Message has been successfully updated." }, status: :ok
    else
      render json: { errors: @outbound_message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def send_email
    outbound_message_validate_service = Desk::Outbound::ValidateMessageService.new(
      @outbound_message, outbound_message_params)

    outbound_message_validate_service.process

    if outbound_message_validate_service.errors.present?
      render json: { errors: outbound_message_validate_service.errors.uniq }, status: :unprocessable_entity
    else
      render json: { notice: outbound_message_validate_service.response }, status: :ok
    end
  end

  def destroy
    @outbound_message.destroy
    render json: { notice: "Outbound message has been successfully deleted." }, status: :ok
  end

  private

    def outbound_message_params
      params.require(:message)
        .except(:conditions, :trix_email_content)
        .permit(
          :id, :message_type, :audience_type, :state, :title, :email_subject,
          :email_content, :created_at, :test_email_recepient,
          rule_attributes: [:name, :description, :_destroy,
            conditions_attributes: [:join_type, :field, :verb, :value, :_destroy]
          ]
        )
    end

    def load_outbound_message!
      @outbound_message = Outbound::Message
        .includes(:latest_message_event, rule: :conditions)
        .with_rich_text_email_content
        .find(params[:id])
    end
end
