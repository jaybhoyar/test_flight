# frozen_string_literal: true

require "test_helper"

class Desk::Organizations::DataSeederServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
  end

  def test_that_default_organization_data_is_created
    ::Desk::Organizations::DataSeederService.new(@organization).process

    @organization.reload

    assert_equal 1, @organization.business_hours.count
    assert_equal 5, @organization.business_hours.first.schedules.count
    assert_equal 1, @organization.business_hours.first.holidays.count
    assert_equal 1, @organization.customer_satisfaction_surveys.count
    assert_equal 9, @organization.rules.count
    assert_equal 4, @organization.tags.count
    assert_equal 3, @organization.desk_macros.count
    assert_equal 6, @organization.tickets.count
  end
end
