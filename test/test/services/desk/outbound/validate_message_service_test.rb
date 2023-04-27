# frozen_string_literal: true

require "test_helper"
class Desk::Outbound::ValidateMessageServiceTest < ActiveSupport::TestCase
  def setup
    @outbound_message = create(:outbound_message)
  end

  def test_validate_message_when_email_subject_is_empty
    outbound_delivery_window = create(
      :outbound_delivery_window, message_id: @outbound_message.id,
      time_zone: "New Delhi")
    schedule = create(:delivery_schedule, delivery_window: outbound_delivery_window)

    @outbound_message.email_subject = ""

    service = Desk::Outbound::ValidateMessageService.new(@outbound_message, outbound_message_params)

    service.process

    assert_equal "The subject field in the email cannot be empty.", service.errors[0]
    assert_equal "Draft", service.outbound_message.state
  end

  def test_validate_message_when_delivery_window_is_not_configured
    service = Desk::Outbound::ValidateMessageService.new(@outbound_message, outbound_message_params)

    service.process

    assert_equal "Delivery window is not configured.", service.errors.first
    assert_equal "Draft", service.outbound_message.state
  end

  def test_broadcast_message_is_queued_for_delivery_when_all_conditions_are_met
    @outbound_message.message_type = "broadcast"
    assert_equal false, @outbound_message.waiting_for_delivery_window

    assert_equal "Draft", @outbound_message.state

    outbound_delivery_window = create(
      :outbound_delivery_window, message_id: @outbound_message.id,
      time_zone: "New Delhi")
    schedule = create(:delivery_schedule, delivery_window: outbound_delivery_window)

    service = Desk::Outbound::ValidateMessageService.new(@outbound_message, { state: "Sent" })

    service.process

    assert_equal "Message has been successfully updated.", service.response
    assert_equal true, @outbound_message.waiting_for_delivery_window
    assert_equal "Sent", @outbound_message.state
  end

  def test_ongoing_message_is_queued_for_delivery_when_all_conditions_are_met
    @outbound_message.message_type = "ongoing"
    assert_equal "Draft", @outbound_message.state

    outbound_delivery_window = create(
      :outbound_delivery_window, message_id: @outbound_message.id,
      time_zone: "New Delhi")
    schedule = create(:delivery_schedule, delivery_window: outbound_delivery_window)

    service = Desk::Outbound::ValidateMessageService.new(@outbound_message, { state: "Live" })

    service.process

    assert_equal "Message has been successfully updated.", service.response
    assert_equal "Live", @outbound_message.state
    assert_equal 1, ::Outbound::Message.Live.processable.count
  end

  private

    def outbound_message_params
      payload = {
        message: {
          state: "Draft",
          message_type: "ongoing",
          title: "Onboarding",
          email_subject: "Subject 101",
          email_content: "An Outbound message for testing"
        }
      }
    end
end
