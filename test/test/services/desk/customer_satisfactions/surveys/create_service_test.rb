# frozen_string_literal: true

require "test_helper"

class Desk::CustomerSatisfactions::Surveys::CreateServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
  end

  def test_creates_new_customer_satisfaction_survey
    default_enabled_survey = create(:default_survey, organization: @organization)

    assert_difference "Desk::CustomerSatisfaction::Survey.count", 1 do
      Desk::CustomerSatisfactions::Surveys::CreateService.new(@organization, create_survey_params).process
    end
  end

  def test_fails_to_create_new_customer_satisfaction_survey
    invalid_create_survey_params = {
      name: ""
    }

    assert_no_difference "Desk::CustomerSatisfaction::Survey.count" do
      Desk::CustomerSatisfactions::Surveys::CreateService.new(@organization, invalid_create_survey_params).process
    end
  end

  def test_deactivates_default_enabled_customer_satisfaction_survey
    default_enabled_survey = create(:default_survey, organization: @organization)
    assert default_enabled_survey.enabled?

    assert_difference "Desk::CustomerSatisfaction::Survey.count", 1 do
      create_survey_service = Desk::CustomerSatisfactions::Surveys::CreateService.new(
        @organization,
        create_survey_params)
      create_survey_service.process

      assert_not default_enabled_survey.reload.enabled?
      assert create_survey_service.survey.enabled?
    end
  end

  private

    def create_survey_params
      {
        name: "Product Satisfaction Survey",
        enabled: true,
        email_state: "closed_ticket",
        acknowledgement_attributes: {
          text: "Thank you for your feedback"
        },
        questions_attributes: [{
          text: "How would you rate the value for moneyf the product",
          default: true,
          display_order: 1,
          point_scale: 3,
          scale_choices_attributes: [
            { text: "Extremely satisfied", display_order: 1 },
            { text: "Neither satisfied nor dissatisfied", display_order: 2 },
            { text: "Extremely dissatisfied", display_order: 3 },
          ]
        }]
      }
    end
end
