# frozen_string_literal: true

require "test_helper"
class Desk::Core::TicketsFinder::FeedbackTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @rule = create :automation_rule, organization: @organization
    @condition_group = create :automation_condition_group, rule: @rule
  end

  def test_matching_ticket_predicate_with_any_value
    create_tickets

    condition = create :automation_condition, conditionable: @condition_group, field: "feedback", verb: "is", value: "any"

    assert_equal 2, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_happy
    create_tickets

    condition = create :automation_condition, conditionable: @condition_group, field: "feedback", verb: "is", value: "happy"

    assert_equal 1, get_query(condition).count
  end

  private

    def get_query(condition)
      service = ::Desk::Core::TicketsFinder::Feedback.new(
        condition.kind, condition.field, condition.verb,
        condition.value, condition.tag_ids)
      ::Ticket.joins(survey_responses: :scale_choice).where(service.matching_ticket_predicate).distinct
    end

    def create_tickets
      @ticket_1 = create :ticket, organization: @organization, subject: "When can I expect my refund?"
      @ticket_2 = create :ticket, organization: @organization, subject: "I am unable to use the application"
      @ticket_3 = create :ticket, organization: @organization, subject: "How to setup the plugin?"

      happy_choice = create :default_question_scale_choice_1
      sad_choice = create :default_question_scale_choice_3

      create :desk_customer_satisfaction_survey_response, ticket: @ticket_1, scale_choice: happy_choice
      create :desk_customer_satisfaction_survey_response, ticket: @ticket_2, scale_choice: sad_choice
    end
end
