# frozen_string_literal: true

require "test_helper"

class Outbound::MessageCarrierTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
    rule = create(:outbound_message_rule, organization: @organization)
    create(:outbound_condition_created_at_any_time, conditionable: rule, sequence: 1)
    @outbound_message = create(
      :outbound_message, waiting_for_delivery_window: true, rule:,
      organization: @organization)
  end

  def test_message_carrier_has_delegated_message_methods
    outbound_message_carrier = Outbound::MessageCarrier.new(@outbound_message)
    assert outbound_message_carrier.respond_to?(:id)
    assert outbound_message_carrier.respond_to?(:title)
    assert outbound_message_carrier.respond_to?(:state)
    assert outbound_message_carrier.respond_to?(:message_type)
    assert outbound_message_carrier.respond_to?(:email_subject)
    assert outbound_message_carrier.respond_to?(:email_content)
    assert outbound_message_carrier.respond_to?(:created_at)
    assert outbound_message_carrier.respond_to?(:rule)
    assert outbound_message_carrier.respond_to?(:latest_message_event)
  end

  def test_message_carrier_returns_correct_notified_recipients_count
    user1 = create(:user, organization: @organization)
    user2 = create(:user, organization: @organization)
    outbound_message_carrier = Outbound::MessageCarrier.new(@outbound_message)

    outbound_message_event = create(:message_event, message_id: @outbound_message.id)
    outbound_message_event2 = create(:message_event, message_id: @outbound_message.id)

    assert_equal 2, outbound_message_carrier.notified_recipients_count
  end
end
