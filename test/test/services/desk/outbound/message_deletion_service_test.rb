# frozen_string_literal: true

require "test_helper"
class Desk::Outbound::MessageDeletionServiceTest < ActiveSupport::TestCase
  def setup
    organization = create(:organization)
    @outbound_broadcast_message = create(
      :outbound_message, waiting_for_delivery_window: true,
      message_type: "broadcast", organization:)
    @outbound_ongoing_message = create(:outbound_message, waiting_for_delivery_window: true, organization:)

    outbound_delivery_window = create(:outbound_delivery_window, message_id: @outbound_broadcast_message.id)
    schedule = create(
      :delivery_schedule, from: DateTime.current - 5.hours, to: DateTime.current + 2.hours,
      delivery_window: outbound_delivery_window)
  end

  def test_that_messages_are_destroyed
    message_ids = [@outbound_broadcast_message.id, @outbound_ongoing_message.id]
    deletion_service = Desk::Outbound::MessageDeletionService.new(message_ids)

    assert_difference "::Outbound::Message.count", -2 do
      deletion_service.process
    end

    assert deletion_service.success?
  end
end
