# frozen_string_literal: true

require "test_helper"

class CustomerSatisfactionSurveyMailerTest < ActionMailer::TestCase
  def setup
    @organization = create(:organization)
    @default_survey = create(:default_survey, organization: @organization)
    survey_question = create(:default_question, survey: @default_survey)
    @ticket = create(:ticket_with_email_config, organization: @organization, requester: create(:user))
    @survey_response = create(:desk_customer_satisfaction_survey_response, scale_choice: nil, ticket: @ticket)
    create(:comment, ticket: @ticket, author: @ticket.requester)
    create(:default_question_scale_choice_1, question: survey_question)

    stub_request(:any, /fonts.googleapis.com/)
  end

  def test_satisfaction_survey_mailer
    email = CustomerSatisfactionSurveyMailer
      .with(
        organization_name: "",
        ticket_id: @ticket.id,
        receiver_id: @ticket.requester_id,
        survey_id: @default_survey.id,
        survey_response_id: @survey_response.id
      )
      .satisfaction_survey
      .deliver_now

    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal [@ticket.email_configuration.forward_to_email], email.from
    assert_equal [@ticket.requester.email], email.to
    assert_equal ["bb@test.com", "bb@best.com"], email.bcc
    assert_includes email.subject, "Re: #{@ticket.subject}"
    assert_includes email.html_part.body.decoded, "TICKETS EMAIL FOOTER CONTENT"
  end

  def test_satisfaction_survey_mailer_with_bcc_setting
    setting = @organization.setting
    setting.update(auto_bcc: true, bcc_email: "test@example.com")

    email = CustomerSatisfactionSurveyMailer
      .with(
        organization_name: "",
        ticket_id: @ticket.id,
        receiver_id: @ticket.requester_id,
        survey_id: @default_survey.id,
        survey_response_id: @survey_response.id
      )
      .satisfaction_survey
      .deliver_now

    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal [@ticket.email_configuration.forward_to_email], email.from
    assert_equal [@ticket.requester.email], email.to
    assert_equal ["bb@test.com", "bb@best.com", "test@example.com"], email.bcc
    assert_includes email.subject, "Re: #{@ticket.subject}"
    assert_includes email.html_part.body.decoded, "TICKETS EMAIL FOOTER CONTENT"
  end
end
