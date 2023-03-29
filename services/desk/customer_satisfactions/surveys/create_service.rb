# frozen_string_literal: true

class Desk::CustomerSatisfactions::Surveys::CreateService < Desk::CustomerSatisfactions::Surveys::BaseService
  attr_reader :survey_params
  attr_accessor :survey

  def initialize(organization, survey_params)
    super(organization)
    @survey_params = survey_params
  end

  def process
    initialize_survey
    process_organization_satisfaction_survey_and_deactivate_enabled_survey

    survey.save
  end

  private

    def initialize_survey
      @survey = organization.customer_satisfaction_surveys.new(survey_params)
    end
end
