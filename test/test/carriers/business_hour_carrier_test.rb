# frozen_string_literal: true

require "test_helper"

class BusinessHourCarrierTest < ActiveSupport::TestCase
  def test_time_zones
    time_zones = TimeZoneCarrier.new.time_zones.map { |time_zone| time_zone[:value] }
    assert_includes time_zones, "Eastern Time (US & Canada)"
  end
end
