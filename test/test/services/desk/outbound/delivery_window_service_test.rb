# frozen_string_literal: true

require "test_helper"
class Desk::Outbound::DeliveryWindowServiceTest < ActiveSupport::TestCase
  def test_process
    outbound_delivery_window = Desk::Outbound::DeliveryWindowService.new.process
    assert_not outbound_delivery_window.schedules.empty?
    assert_nil outbound_delivery_window.id
  end

  def test_find_and_create_schedules
    outbound_delivery_window = create(:outbound_delivery_window)
    Desk::Outbound::DeliveryWindowService.new.find_and_create_schedules(outbound_delivery_window.id)
    assert_equal 7, outbound_delivery_window.schedules.count
    assert outbound_delivery_window.schedules.sort_by_day.first.active?
  end
end
