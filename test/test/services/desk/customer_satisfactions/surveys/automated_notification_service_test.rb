# frozen_string_literal: true

require "test_helper"

class Desk::CustomerSatisfactions::Surveys::AutomatedNotificationServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
    stub_request(:any, /fonts.googleapis.com/)
  end

  def test_that_survey_emails_are_not_sent_for_twitter_tickets
    ticket = create(
      :ticket, channel: :twitter, organization: @organization, status: :resolved,
      requester: create(:user))
    assert_no_emails do
      Desk::CustomerSatisfactions::Surveys::AutomatedNotificationService.new(ticket).process
    end
  end

  def test_sends_satisfaction_survey_email_when_default_survey_setting_and_ticket_status_is_closed
    setup_customer_satisfaction_survey_setting("closed_ticket", Ticket::DEFAULT_STATUSES[:closed])

    assert_emails 1 do
      Desk::CustomerSatisfactions::Surveys::AutomatedNotificationService.new(@ticket).process
    end
  end

  def test_sends_satisfaction_survey_email_when_default_survey_setting_and_ticket_status_is_resolved
    setup_customer_satisfaction_survey_setting("resolved_ticket", Ticket::DEFAULT_STATUSES[:resolved])

    assert_emails 1 do
      Desk::CustomerSatisfactions::Surveys::AutomatedNotificationService.new(@ticket).process
    end
  end

  def test_creates_temporary_survey_response_for_ticket
    assert_difference "Desk::CustomerSatisfaction::SurveyResponse.count", 1 do
      setup_customer_satisfaction_survey_setting("resolved_ticket", Ticket::DEFAULT_STATUSES[:resolved])
      Desk::CustomerSatisfactions::Surveys::AutomatedNotificationService.new(@ticket).process
    end
  end

  private

    def setup_customer_satisfaction_survey_setting(email_state, ticket_status)
      @survey = create(:default_survey, organization: @organization, email_state:)
      survey_question = create(:default_question, survey: @survey)
      @survey_scale_choice = create(:default_question_scale_choice_1, question: survey_question)

      @ticket = create(
        :ticket_with_email_config, organization: @organization,
        status: ticket_status, requester: create(:user))
      create(:comment, ticket: @ticket, author: @ticket.requester)
    end
end
