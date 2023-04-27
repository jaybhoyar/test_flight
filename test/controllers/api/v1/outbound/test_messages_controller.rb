# frozen_string_literal: true

class Api::V1::Outbound::TestMessagesController < Api::V1::BaseController
  before_action :load_outbound_message!, only: :send_test_email

  def send_test_email
    test_email_recepient = params[:test_message][:test_email_recepient]
    if @outbound_test_message.perform_outbound_test_message_delivery(test_email_recepient)
      render json: { notice: "Test message has been sent successfully." }, status: :ok
    else
      render json: { errors: @outbound_test_message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def outbound_test_message_params
      params.require(:test_message)
        .permit(
          :id,
          :message_type,
          :state,
          :email_subject,
          :email_content,
          test_email_recepient: []
        )
        .merge(sender: current_user)
    end

    def load_outbound_message!
      @outbound_test_message = Outbound::Message.find(params[:id])
    end
end
