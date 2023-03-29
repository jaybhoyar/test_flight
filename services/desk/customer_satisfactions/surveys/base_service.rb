# frozen_string_literal: true

class Desk::CustomerSatisfactions::Surveys::BaseService
  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  private

    def process_organization_satisfaction_survey_and_deactivate_enabled_survey
      return if !survey.enabled? || active_survey.nil?

      active_survey.update(enabled: false)
    end

    def active_survey
      @_active_survey ||= organization.customer_satisfaction_surveys.where.not(id: survey.id).enabled
    end
end
