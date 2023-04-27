# frozen_string_literal: true

require "test_helper"
class Desk::BusinessHours::CreationServiceTest < ActiveSupport::TestCase
  def test_process
    business_hour = Desk::BusinessHours::CreationService.new.process
    assert_not business_hour.schedules.empty?
    assert_nil business_hour.id
  end

  def test_find_and_create_schedules
    business_hour = create(:business_hour)
    Desk::BusinessHours::CreationService.new.find_and_create_schedules(business_hour.id)
    assert_equal 5, business_hour.schedules.count
    assert business_hour.schedules.order_by_day.first.active?
  end
end
