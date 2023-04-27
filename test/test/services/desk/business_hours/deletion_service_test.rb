# frozen_string_literal: true

require "test_helper"

class Desk::BusinessHours::DeletionServiceTest < ActiveSupport::TestCase
  def setup
    @business_hour_one = create(:business_hour)
    @business_hour_two = create(:business_hour)
  end

  def test_delete_business_hours_success
    business_hours_deletion_service = Desk::BusinessHours::DeletionService.new(
      [@business_hour_one,
      @business_hour_two]).process

    assert_equal "Business Hours have been successfully deleted", business_hours_deletion_service
  end

  def test_delete_business_hour_success
    business_hours_deletion_service = Desk::BusinessHours::DeletionService.new([@business_hour_one]).process

    assert_equal "Business Hour has been successfully deleted", business_hours_deletion_service
  end
end
