# frozen_string_literal: true

require "test_helper"

class Desk::CustomerSatisfactions::SurveyResponses::UpdateScaleChoiceServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
    @survey = create(:default_survey, organization: @organization)
    survey_question = create(:default_question, survey: @survey)
    @survey_scale_choice = create(:default_question_scale_choice_1, question: survey_question)

    user = create :user, organization: @organization
    @ticket = create(:ticket, organization: @organization, requester: user)
    @survey_response = create(:desk_customer_satisfaction_survey_response, scale_choice: nil, ticket: @ticket)
  end

  def test_update_survey_response_scale_choice_success
    params = survey_response_params(@survey_response.id, @survey_scale_choice.slug)

    survey_response_update_scale_choice_service =
      Desk::CustomerSatisfactions::SurveyResponses::UpdateScaleChoiceService.new(params)

    assert survey_response_update_scale_choice_service.process
    assert_equal @survey_scale_choice.id,
      survey_response_update_scale_choice_service.survey_response.scale_choice_id
  end

  def test_update_survey_response_fails_for_invalid_survey_response_id
    params = survey_response_params(0, @survey_scale_choice.slug)

    assert_raises do
      Desk::CustomerSatisfactions::SurveyResponses::UpdateScaleChoiceService.new(params).process
    end
  end

  def test_update_survey_response_fails_for_invalid_scale_choice_slug
    params = survey_response_params(@survey_response.id, "invalid_choice")

    assert_raises do
      Desk::CustomerSatisfactions::SurveyResponses::UpdateScaleChoiceService.new(params).process
    end
  end

  def test_that_matching_rule_is_applied_on_when_survey_is_submitted
    Sidekiq::Testing.inline!

    rule = create :automation_rule, :on_feedback_received, organization: @organization
    group = create :automation_condition_group, rule: rule
    create :desk_core_condition, conditionable: group, field: "feedback", verb: "is", value: "extremely_happy"
    create :automation_action, rule: rule, name: "add_note", body: "Thank you!"

    params = survey_response_params(@survey_response.id, @survey_scale_choice.slug)

    service = Desk::CustomerSatisfactions::SurveyResponses::UpdateScaleChoiceService.new(params)

    assert_difference ["Desk::Automation::ExecutionLogEntry.count", "Comment.count"] do
      assert service.process
    end
  end

  def test_that_rule_is_not_executed_when_choice_is_invalid
    params = survey_response_params(@survey_response.id, "invalid_choice")

    assert_no_difference ["Desk::Automation::ExecutionLogEntry.count", "Comment.count"] do
      assert_raises do
        Desk::CustomerSatisfactions::SurveyResponses::UpdateScaleChoiceService.new(params).process
      end
    end
  end

  private

    def survey_response_params(survey_response_id, scale_choice_slug)
      {
        id: survey_response_id,
        scale_choice_slug:
      }
    end
end
