# frozen_string_literal: true

require "test_helper"
class Desk::Core::TicketsFinder::BusinessHoursTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @rule = create :automation_rule, organization: @organization

    @ticket_1 = create :ticket, organization: @organization, subject: "When can I expect my refund?"
  end

  def test_tickets_for_created_at_with_during
    business_hour = create :business_hour, :weekend, organization: @organization
    @ticket_1.update(created_at: last_saturday)

    condition = create :automation_condition,
      conditionable: @rule,
      field: "created_at",
      verb: "during",
      value: business_hour.id

    service = get_service(condition)
    assert_equal 1, ::Ticket.where(service.matching_ticket_predicate).count
  end

  def test_tickets_for_created_at_with_not_during
    business_hour = create :business_hour, :weekend, organization: @organization

    @ticket_1.update(created_at: last_saturday)

    condition = create :automation_condition, conditionable: @rule, field: "created_at", verb: "not_during",
      value: business_hour.id

    service = get_service(condition)
    assert_equal 0, ::Ticket.where(service.matching_ticket_predicate).count
  end

  def test_tickets_for_created_at_as_any_time
    condition = create :automation_condition, conditionable: @rule, field: "created_at", verb: "any_time", value: ""

    service = get_service(condition)
    assert_equal 1, ::Ticket.where(service.matching_ticket_predicate).count
  end

  def test_tickets_for_created_at_during_wrong_business_hour_id
    business_hour = create :business_hour, :weekend, organization: @organization
    @ticket_1.update(created_at: last_saturday)

    condition = create :automation_condition, conditionable: @rule, field: "created_at", verb: "during", value: "wrong_id"

    service = get_service(condition)
    assert_empty ::Ticket.where(service.matching_ticket_predicate)
  end

  private

    def get_service(condition)
      ::Desk::Core::TicketsFinder::BusinessHours.new(
        condition.kind, condition.field, condition.verb, condition.value, condition.tag_ids
      )
    end

    def last_saturday
      @_last_saturday ||= Time.current.beginning_of_week.advance(days: -2, hours: 10)
    end
end
