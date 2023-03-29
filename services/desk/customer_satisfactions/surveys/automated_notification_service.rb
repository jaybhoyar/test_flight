# frozen_string_literal: true

class Desk::CustomerSatisfactions::Surveys::AutomatedNotificationService
  attr_reader :ticket, :organization, :survey_response

  TICKET_STATUS_MAPPING = {
    resolved_ticket: "resolved",
    closed_ticket: "closed"
  }

  def initialize(ticket)
    @ticket = ticket
    @organization = ticket.organization
  end

  def process
    return unless can_send_customer_satisfaction_survey_email?

    @survey_response = ticket.survey_responses.create!

    CustomerSatisfactionSurveyMailer
      .with(
        organization_name: "",
        ticket_id: ticket.id,
        receiver_id: ticket.requester_id,
        survey_id: active_survey.id,
        survey_response_id: @survey_response.id
      )
      .satisfaction_survey
      .deliver_later
  end

  private

    def can_send_customer_satisfaction_survey_email?
      if !ticket.twitter? && active_survey.present?
        TICKET_STATUS_MAPPING[active_survey.email_state.to_sym].eql?(ticket.status)
      end
    end

    def active_survey
      @_active_survey ||= organization.customer_satisfaction_surveys.enabled
    end
end
