# frozen_string_literal: true

require "test_helper"

class Outbound::MessageTest < ActiveSupport::TestCase
  require "sidekiq/testing"

  def setup
    travel_to DateTime.parse("6:00 PM")
    @outbound_message = create(:outbound_message)
    @outbound_message_event = create(:message_event, message_id: @outbound_message.id)
    @outbound_message_event2 = create(
      :message_event,
      message_id: @outbound_message.id)
    @outbound_message_event3 = create(
      :message_event,
      message_id: @outbound_message.id, created_at: Time.current + 2.days)
  end

  def teardown
    travel_back
  end

  def test_outbound_message_validation
    assert @outbound_message.valid?
  end

  def test_check_current_time_in_delivery_window
    outbound_delivery_window = create(:outbound_delivery_window, message_id: @outbound_message.id)
    schedule = create(
      :delivery_schedule, from: DateTime.current - 5.hours, to: DateTime.current + 2.hours,
      delivery_window: outbound_delivery_window)
    assert @outbound_message.check_current_time_in_delivery_window?
  end

  def test_message_recipents_count_returns_correct_users
    notified_recipients = @outbound_message.notified_recipients
    assert_equal 3, notified_recipients.count
    assert notified_recipients.include?(@outbound_message_event.user)
  end
end
