# frozen_string_literal: true

require "test_helper"

class Outbound::DeliveryWindowTest < ActiveSupport::TestCase
  def setup
    @outbound_message = create(:outbound_message)
  end

  def test_name_should_not_be_blank
    outbound_delivery_window = Outbound::DeliveryWindow.new(message: @outbound_message)
    assert_not outbound_delivery_window.valid?
    assert_equal ["can't be blank"], outbound_delivery_window.errors.messages[:name]
  end

  def test_should_not_have_duplicate_names
    outbound_delivery_window = create(:outbound_delivery_window, message: @outbound_message)
    outbound_delivery_window_dup = build(:outbound_delivery_window, message: @outbound_message)
    assert_not outbound_delivery_window_dup.valid?
    assert_equal ["has already been taken"], outbound_delivery_window_dup.errors.messages[:name]
  end

  def test_should_not_be_valid_without_outbound_message
    outbound_delivery_window = build(:outbound_delivery_window, message: nil)
    assert_not outbound_delivery_window.valid?
  end

  def test_should_not_be_valid_without_time_zone
    outbound_delivery_window = build(:outbound_delivery_window, time_zone: nil)
    assert_not outbound_delivery_window.valid?
  end
end
