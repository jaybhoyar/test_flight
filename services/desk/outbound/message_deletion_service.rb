# frozen_string_literal: true

class Desk::Outbound::MessageDeletionService
  attr_reader :outbound_messages, :response, :errors

  def initialize(outbound_message_ids)
    @outbound_messages = ::Outbound::Message.where(id: outbound_message_ids)
    @errors = []
    @response = { message: "", success: false }
  end

  def process
    destroy_outbound_messages
    set_json_response
  end

  def success?
    response[:success]
  end

  private

    def destroy_outbound_messages
      ::Outbound::Message.transaction do
        outbound_messages.each do |outbound_message|
          begin
            outbound_message.destroy!
          rescue ActiveRecord::RecordNotDestroyed => exception
            set_errors(exception.record.errors.full_messages)
          end
        end
      end
    end

    def set_errors(message)
      @errors << message
    end

    def set_json_response
      @response = if errors.present?
        { error: errors.to_sentence, success: false }
      else
        { notice: I18n.t("outbound.message.destroy_success"), success: true }
      end
    end
end
