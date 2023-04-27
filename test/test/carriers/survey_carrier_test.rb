# frozen_string_literal: true

require "test_helper"

class SurveyCarrierTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
  end

  def test_survey_carrier_point_scale_options
    survey_carrier = CustomerSatisfactions::SurveyCarrier.new(@organization)

    assert_equal Desk::CustomerSatisfaction::Question::ALLOWED_POINT_SCALES.count,
      survey_carrier.point_scale_options.count
  end

  def test_survey_carrier_scale_choice_options
    survey_carrier = CustomerSatisfactions::SurveyCarrier.new(@organization)

    assert_equal Desk::CustomerSatisfaction::ScaleChoice::ALLOWED_POINT_SCALE_CHOICES.size,
      survey_carrier.scale_choice_options.size
  end

  def test_survey_carrier_email_state_options
    survey_carrier = CustomerSatisfactions::SurveyCarrier.new(@organization)

    assert_equal Desk::CustomerSatisfaction::Survey.email_states.count,
      survey_carrier.email_state_options.count
  end

  def test_is_other_satisfaction_survey_enabled_if_current_survey_is_enabled
    survey = create(:default_survey, organization: @organization)
    survey_carrier = CustomerSatisfactions::SurveyCarrier.new(@organization, survey)

    assert_not survey_carrier.is_other_satisfaction_survey_enabled?
  end

  def test_is_other_satisfaction_survey_enabled_if_current_survey_is_not_enabled
    survey = create(:default_survey, organization: @organization, enabled: false)
    other_survey = create(:another_survey, organization: @organization)

    survey_carrier = CustomerSatisfactions::SurveyCarrier.new(@organization, survey)
    assert survey_carrier.is_other_satisfaction_survey_enabled?

    survey_carrier = CustomerSatisfactions::SurveyCarrier.new(@organization)
    assert survey_carrier.is_other_satisfaction_survey_enabled?
  end

  def test_survey_carrier_return_enabled_satisfaction_survey_name
    survey = create(:default_survey, organization: @organization)
    survey_carrier = CustomerSatisfactions::SurveyCarrier.new(@organization, survey)

    assert_equal survey.name, survey_carrier.enabled_satisfaction_survey_name
  end
end
