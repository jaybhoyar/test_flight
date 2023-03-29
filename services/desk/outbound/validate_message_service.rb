# frozen_string_literal: true

class Desk::Outbound::ValidateMessageService
  attr_reader :outbound_message, :outbound_message_params, :response
  attr_accessor :errors

  def initialize(outbound_message, outbound_message_params)
    @outbound_message = outbound_message
    @outbound_message_params = outbound_message_params
  end

  def process
    validate_if_message_can_be_sent
    json_response
  end

  private

    def validate_if_message_can_be_sent
      if outbound_message.email_subject? &&
        outbound_message.email_content.present? &&
        outbound_message.delivery_windows.present?

        outbound_message.update!(outbound_message_params)

        outbound_message.queue_broadcast_message_for_delivery if outbound_message.message_type == "broadcast"

      elsif outbound_message.email_subject.blank?
        outbound_message.errors.add(:base, "The subject field in the email cannot be empty.")
        set_errors
      elsif outbound_message.email_content.blank?
        outbound_message.errors.add(:base, "Message content for email cannot be empty.")
        set_errors
      else
        outbound_message.errors.add(:base, "Delivery window is not configured.")
        set_errors
      end
    end

    def set_errors
      @errors = outbound_message.errors.full_messages
    end

    def json_response
      @response = "Message has been successfully updated." if @errors.nil?
    end
end
