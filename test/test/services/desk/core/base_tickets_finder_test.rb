# frozen_string_literal: true

require "test_helper"
class Desk::Core::BaseTicketsFinderTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    rule = create :automation_rule, organization: @organization
    group = create :automation_condition_group, rule: rule
    @condition = create :desk_core_condition, conditionable: group, field: "subject", verb: "contains", value: "refund"
  end

  def test_valid_verb
    service = get_service
    assert service.valid_verb?

    service = ::Desk::Core::BaseTicketsFinder.new(@condition.kind, @condition.field, "wrong_verb", @condition.value)
    assert_not service.valid_verb?
  end

  def test_arel_methods
    service = get_service

    assert_nothing_raised do
      service.tickets
      service.users
      service.taggings
      service.activities
      service.comments
      service.survey_responses
      service.scale_choices
      service.action_text_rich_texts
      service.desk_ticket_field_responses
    end
  end

  def test_empty_result_predicate
    service = get_service

    assert_empty ::Ticket.where(service.empty_result_predicate)
  end

  def test_requesters_join_join
    create_tickets
    service = get_service

    assert_equal 2, ::Ticket.joins(service.requesters_join).count
  end

  def test_tags_join
    create_tickets
    service = get_service
    tag = create :ticket_tag
    @ticket_1.tags << tag

    assert_equal 1, ::Ticket.joins(service.tags_join).count
  end

  def test_activities_join
    create_tickets
    service = get_service

    assert_equal 2, ::Ticket.joins(service.activities_join).count
  end

  def test_ticket_fields_join
    create_tickets

    ticket_field = create :ticket_field, organization: @organization
    create :ticket_field_response, ticket_field: ticket_field, owner: @ticket_1
    create :ticket_field_response, ticket_field: ticket_field, owner: @ticket_2

    @condition.update(field: ticket_field.id, kind: :ticket_field)

    service = get_service

    assert_equal 2, ::Ticket.joins(service.desk_ticket_fields_join).count
  end

  def test_feedbacks
    create_tickets
    create :desk_customer_satisfaction_survey_response, ticket: @ticket_1

    assert_equal 1, ::Ticket.joins(get_service.feedbacks_join).count
  end

  def test_created_on_day_func
    create_tickets
    service = get_service
    @ticket_1.update(created_at: Time.current)
    @ticket_2.update(created_at: 1.day.ago)

    today_name = Time.current.strftime("%A")
    assert_equal 1, ::Ticket.where(service.created_on_day.eq(today_name)).count
  end

  def test_created_at_time_func
    create_tickets
    service = get_service

    today_time = Time.current.beginning_of_day
    @ticket_1.update(created_at: today_time + 8.hours)
    @ticket_2.update(created_at: today_time + 10.hours)

    assert_equal 1, ::Ticket.where(service.created_at_time.between("06:00:00".."09:00:00")).count
  end

  def test_cast_field_as_integer
    create_tickets

    ticket_field = create :ticket_field, organization: @organization
    create :ticket_field_response, ticket_field: ticket_field, owner: @ticket_1, value: "10"
    create :ticket_field_response, ticket_field: ticket_field, owner: @ticket_2, value: "20"

    @condition.update(field: ticket_field.id, kind: :ticket_field)

    service = get_service

    today_time = Time.current.beginning_of_day
    @ticket_1.update(created_at: today_time + 8.hours)
    @ticket_2.update(created_at: today_time + 10.hours)

    field = service.desk_ticket_field_responses[:value]
    predicate = service.cast_field_as_integer(field).lt("15")

    assert_equal 1, ::Ticket.joins(:ticket_field_responses).where(predicate).count
  end

  private

    def get_service
      ::Desk::Core::BaseTicketsFinder.new(@condition.kind, @condition.field, @condition.verb, @condition.value)
    end

    def create_tickets
      user = create(:user, organization: @organization)
      @ticket_1 = create :ticket, requester: user, organization: user.organization, subject: "When can I expect my refund?"
      @ticket_2 = create :ticket, requester: user, organization: user.organization, subject: "I am unable to use the application"
    end
end
