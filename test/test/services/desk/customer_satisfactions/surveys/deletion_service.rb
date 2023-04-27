# frozen_string_literal: true

require "test_helper"

class Desk::CustomerSatisfactions::Surveys::DeletionServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
    @survey = create(:default_survey, organization: @organization, enabled: false)
    @survey_one = create(:another_survey, organization: @organization, enabled: false)
    @survey_two = create(:another_survey, name: "Some other survey", organization: @organization, enabled: false)
  end

  def test_deletes_multiple_customer_satifaction_surveys
    service = Desk::CustomerSatisfactions::Surveys::DeletionService.new([@survey_one, @survey_two])
    assert_difference "Desk::CustomerSatisfaction::Survey.count", -2 do
      service.process
    end
    assert_equal "Surveys have been successfully deleted.", service.response
  end

  def test_deletes_single_customer_satifaction_surveys
    service = Desk::CustomerSatisfactions::Surveys::DeletionService.new([@survey_one])
    assert_difference "Desk::CustomerSatisfaction::Survey.count", -1 do
      service.process
    end
    assert_equal "Survey has been successfully deleted.", service.response
  end
end
