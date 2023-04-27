# frozen_string_literal: true

require "test_helper"

class Desk::CustomerSatisfactions::Surveys::UpdateServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
    @survey = create(:default_survey, organization: @organization, enabled: false)
  end

  def test_updates_customer_satisfaction_survey
    # default_enabled_survey = create(:default_survey, organization: @organization)

    update_survey_service = Desk::CustomerSatisfactions::Surveys::UpdateService.new(
      @organization,
      update_survey_params,
      @survey)
    assert update_survey_service.process
    assert update_survey_service.survey.valid?

    @survey.reload
    assert @survey.enabled?
    assert "neetoDesk Satisfaction Survey", @survey.name
  end

  def test_fails_to_update_customer_satisfaction_survey
    invalid_update_survey_params = {
      name: ""
    }

    update_survey_service = Desk::CustomerSatisfactions::Surveys::UpdateService.new(
      @organization,
      invalid_update_survey_params,
      @survey)
    assert_not update_survey_service.process
    assert_not update_survey_service.survey.valid?
  end

  def test_deactivates_default_enabled_customer_satisfaction_survey
    another_enabled_survey = create(
      :another_survey,
      organization: @organization)
    assert another_enabled_survey.enabled?

    update_survey_service = Desk::CustomerSatisfactions::Surveys::UpdateService.new(
      @organization,
      update_survey_params,
      @survey)
    update_survey_service.process

    assert_not another_enabled_survey.reload.enabled?

    @survey.reload
    assert @survey.enabled?
    assert "neetoDesk Satisfaction Survey", @survey.name
  end

  def test_that_default_survey_is_not_deactivated_after_edit
    @survey.update(enabled: true)

    update_survey_service = Desk::CustomerSatisfactions::Surveys::UpdateService.new(
      @organization,
      update_survey_params,
      @survey)
    update_survey_service.process

    @survey.reload
    assert @survey.enabled?
    assert "neetoDesk Satisfaction Survey", @survey.name
  end

  private

    def update_survey_params
      {
        name: "neetoDesk Satisfaction Survey",
        enabled: true
      }
    end
end
