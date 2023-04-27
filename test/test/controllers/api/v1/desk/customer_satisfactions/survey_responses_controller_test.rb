# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::CustomerSatisfactions::SurveyResponsesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization

    setup_customer_satisfaction_survey_factories
    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_successfully_update_to_customer_satisfaction_survey_response
    update_survey_response_params = { survey_response: { comment: "Thanks for quick follow up on issue." } }

    patch api_v1_desk_customer_satisfactions_survey_response_url(@survey_response),
      params: update_survey_response_params,
      headers: headers(@user)

    assert_equal "Thanks for quick follow up on issue.", @survey_response.reload.comment
    assert_equal ["comment", "id", "organization", "scale_choice", "scale_choices", "survey_acknowledgement"],
      json_body["survey_response"].keys.sort
  end

  private

    def setup_customer_satisfaction_survey_factories
      survey = create(:default_survey, organization: @organization)
      ticket = create(:ticket_with_email_config, organization: @organization)
      @survey_response = create(:desk_customer_satisfaction_survey_response, ticket:)
      create(:default_survey_acknowlegement, survey:)

      question = create :default_question, survey: survey
      create :default_question_scale_choice_1, question: question
      create :default_question_scale_choice_2, question: question
      create :default_question_scale_choice_3, question:
    end
end
