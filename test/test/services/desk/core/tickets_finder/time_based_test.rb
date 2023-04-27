# frozen_string_literal: true

require "test_helper"
class Desk::Core::TicketsFinder::TimeBasedTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @rule = create :automation_rule, organization: @organization
  end

  def test_matching_ticket_predicate_with_is
    create_tickets

    @ticket_1.update(status: "open")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from New to Open",
      created_at: Time.current - 2.hours

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "status.hours.open", verb: "is", value: "2"

    assert_equal 1, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_greater_than
    create_tickets

    @ticket_1.update(status: "open")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from New to Open",
      created_at: Time.current - 2.hours

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "status.hours.open", verb: "greater_than", value: "1"

    assert_equal 1, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_less_than
    create_tickets

    @ticket_1.update(status: "open")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from New to Open",
      created_at: Time.current - 2.hours

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "status.hours.open", verb: "less_than", value: "4"

    assert_equal 1, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_less_than_for_new_ticket
    create_tickets

    @ticket_1.update(status: "new", created_at: Time.current - 2.hours)
    @ticket_2.update(status: "new", created_at: Time.current - 2.hours)

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "status.hours.new", verb: "less_than", value: "4"

    assert_equal 2, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_less_than_for_open
    create_tickets

    @ticket_1.update(status: "open")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from New to Open",
      created_at: Time.current - 2.hours

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "status.hours.open", verb: "less_than", value: "4"

    assert_equal 1, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_less_than_for_on_hold
    create_tickets

    @ticket_1.update(status: "on_hold")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from Open to On Hold",
      created_at: Time.current - 2.hours

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "status.hours.on_hold", verb: "less_than", value: "4"

    assert_equal 1, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_less_than_for_waiting_on_customer
    create_tickets

    @ticket_1.update(status: "waiting_on_customer")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from Open to Waiting On Customer",
      created_at: Time.current - 2.hours

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "status.hours.waiting_on_customer", verb: "less_than", value: "4"

    assert_equal 1, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_less_than_for_resolved
    create_tickets

    @ticket_1.update(status: "resolved")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from Open to Resolved",
      created_at: Time.current - 2.hours

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "status.hours.resolved", verb: "less_than", value: "4"

    assert_equal 1, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_less_than_for_closed
    create_tickets

    @ticket_1.update(status: "closed")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from Open to Closed",
      created_at: Time.current - 2.hours

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "status.hours.closed", verb: "less_than", value: "4"

    assert_equal 1, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_less_than_for_spam
    create_tickets

    @ticket_1.update!(status: "spam")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from Open to Spam",
      created_at: Time.current - 2.hours

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "status.hours.spam", verb: "less_than", value: "4"

    assert_equal 1, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_less_than_for_trash
    create_tickets

    @ticket_1.update!(status: "trash")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from Open to Trash",
      created_at: Time.current - 2.hours

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "status.hours.trash", verb: "less_than", value: "4"

    assert_equal 1, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_less_than_for_hours_since_created
    create_tickets

    @ticket_1.update(status: "new", created_at: Time.current - 2.hours)
    @ticket_2.update(status: "new", created_at: Time.current - 2.hours)

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "status.hours.created", verb: "less_than", value: "4"

    assert_equal 2, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_less_than_for_hours_since_updated_by_agent_or_requester
    create_tickets

    @ticket_1.update(last_agent_updated_at: Time.current - 2.hours)
    @ticket_2.update(last_requester_updated_at: Time.current - 2.hours)

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "updated_at_by_agent_or_requester", verb: "less_than", value: "4"

    assert_equal 2, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_less_than_for_hours_since_updated_by_requester
    create_tickets

    @ticket_1.update(last_agent_updated_at: Time.current - 2.hours)
    @ticket_2.update(last_requester_updated_at: Time.current - 2.hours)

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "last_requester_updated_at", verb: "less_than", value: "4"

    assert_equal 1, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_less_than_for_hours_since_assigned_at
    create_tickets

    @ticket_1.update(assigned_at: Time.current - 2.hours)
    @ticket_2.update(last_assigned_at: Time.current - 2.hours)

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "assigned_at", verb: "less_than", value: "4"

    assert_equal 1, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_less_than_for_hours_since_last_assigned_at
    create_tickets

    @ticket_1.update(assigned_at: Time.current - 2.hours)
    @ticket_2.update(last_assigned_at: Time.current - 2.hours)

    condition = create :automation_condition, :time_based, conditionable: @rule, field: "last_assigned_at", verb: "less_than", value: "4"

    assert_equal 1, get_query(condition).count
  end

  private

    def get_query(condition)
      service = ::Desk::Core::TicketsFinder::TimeBased.new(
        condition.kind, condition.field, condition.verb,
        condition.value, condition.tag_ids)
      ::Ticket.joins(:activities).where(service.matching_ticket_predicate).distinct
    end

    def create_tickets
      @ticket_1 = create :ticket, organization: @organization, subject: "When can I expect my refund?"
      @ticket_2 = create :ticket, organization: @organization, subject: "I am unable to use the application"
    end
end
