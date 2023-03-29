# frozen_string_literal: true

class Desk::CustomerSatisfactions::SurveyResponses::UpdateScaleChoiceService
  attr_reader :survey_response, :scale_choice, :params

  def initialize(params)
    @params = params
  end

  def process
    ActiveRecord::Base.transaction do
      load_survey_response!
      load_organization
      load_customer_satisfaction_default_survey_scale_choice!

      is_valid = survey_response.update!(scale_choice:)

      instrument_feedback_notification if is_valid
      is_valid
    end
  end

  private

    def load_survey_response!
      @survey_response = Desk::CustomerSatisfaction::SurveyResponse.find_by!(id: params[:id])
    end

    def load_organization
      @organization = @survey_response.ticket.organization
    end

    def load_customer_satisfaction_default_survey_scale_choice!
      default_survey = @organization.customer_satisfaction_surveys.enabled
      @scale_choice = default_survey.scale_choices.find_by!(slug: params[:scale_choice_slug])
    end

    def instrument_feedback_notification
      ActiveSupport::Notifications.instrument(
        "ticket.updated.feedback.received", ticket: @survey_response.ticket,
        performed_by: "requester")
    end
end
