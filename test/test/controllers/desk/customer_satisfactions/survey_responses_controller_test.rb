# frozen_string_literal: true

require "test_helper"

class Desk::CustomerSatisfactions::SurveyResponsesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization

    setup_survey_response_factories
    sign_in(@user)
  end

  def test_update_survey_response_scale_choice_success
    get desk_survey_response_url(@survey_response.id, @survey_scale_choice.slug)

    assert_response :found
    assert_equal @survey_scale_choice.id, @survey_response.reload.scale_choice.id
  end

  def test_that_matching_rule_is_applied_on_when_survey_is_submitted
    Sidekiq::Testing.inline!

    rule = create :automation_rule, :on_feedback_received, organization: @organization
    group = create :automation_condition_group, rule: rule
    create :desk_core_condition, conditionable: group, field: "feedback", verb: "is", value: "happy"
    create :automation_action, rule: rule, name: "add_note", body: "Thank you!"

    assert_difference ["Desk::Automation::ExecutionLogEntry.count", "Comment.count"] do
      get desk_survey_response_url(@survey_response.id, @survey_scale_choice.slug)
    end

    assert_match "Thank you!", @ticket.comments.note.last.info.to_s
  end

  private

    def setup_survey_response_factories
      @survey = create(:default_survey, organization: @organization)
      survey_question = create(:default_question, survey: @survey)
      @survey_scale_choice = create(:default_question_scale_choice_1, question: survey_question)
      @ticket = create(:ticket, organization: @organization, requester: @user)
      @survey_response = create(:desk_customer_satisfaction_survey_response, scale_choice: nil, ticket: @ticket)
    end
end
