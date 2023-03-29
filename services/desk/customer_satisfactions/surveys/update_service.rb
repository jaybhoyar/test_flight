# frozen_string_literal: true

class Desk::CustomerSatisfactions::Surveys::UpdateService < Desk::CustomerSatisfactions::Surveys::BaseService
  attr_reader :survey_params, :survey

  def initialize(organization, survey_params, survey)
    super(organization)
    @survey = survey
    @survey_params = survey_params
  end

  def process
    initialize_survey_attributes
    process_organization_satisfaction_survey_and_deactivate_enabled_survey

    survey.save
  end

  private

    def initialize_survey_attributes
      survey.assign_attributes(survey_params)
    end
end
