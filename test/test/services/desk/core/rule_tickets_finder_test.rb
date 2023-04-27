# frozen_string_literal: true

require "test_helper"
class Desk::Core::RuleTicketsFinderTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization

    aditya = create :user, email: "aditya.varma@example.com"
    rohit = create :user, email: "rohit.sharma@example.com"
    virat = create :user, email: "virat.shetty@example.com"
    @amit = create :user, email: "amit.mehta@example.com"
    @atish = create :user, email: "atish.baji@example.com"

    @ticket_1 = create :ticket, :with_desc, requester: aditya, agent: @amit, organization: @organization, subject: "When can I expect my refund?"
    @ticket_2 = create :ticket, :with_desc, requester: aditya, agent: @amit, organization: @organization, subject: "I am unable to use the application"
    @ticket_3 = create :ticket, :with_desc, requester: rohit, agent: @atish, organization: @organization, subject: "I am having issues with the plugin"
    @ticket_4 = create :ticket, :with_desc, requester: virat, agent: @atish, organization: @organization, subject: "Where is help section in the app"
    @ticket_5 = create :ticket, :with_desc, requester: virat, agent: @atish, organization: @organization, subject: "How to read the documentation, I need help!"

    @rule = create :automation_rule, organization: @organization
  end

  def test_tickets_for_subject_with_contains
    group = create :automation_condition_group, :match_any, rule: @rule
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "refund"
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "application"

    matching_tickets = get_matching_tickets
    assert_equal 2, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
    assert_includes matching_tickets, @ticket_2
  end

  def test_tickets_for_subject_with_contains_multiple_groups
    group_1 = create :automation_condition_group, :match_any, rule: @rule
    group_2 = create :automation_condition_group, :match_any, join_type: "or_operator", rule: @rule

    create :automation_condition, conditionable: group_1, field: "subject", verb: "contains", value: "refund"
    create :automation_condition, conditionable: group_2, field: "subject", verb: "contains", value: "application"

    matching_tickets = get_matching_tickets
    assert_equal 2, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
    assert_includes matching_tickets, @ticket_2
  end

  def test_tickets_for_subject_with_contains_multiple_groups_and
    group_1 = create :automation_condition_group, :match_any, rule: @rule
    group_2 = create :automation_condition_group, :match_any, join_type: "and_operator", rule: @rule

    create :automation_condition, conditionable: group_1, field: "subject", verb: "contains", value: "refund"
    create :automation_condition, conditionable: group_2, field: "subject", verb: "contains", value: "application"

    matching_tickets = get_matching_tickets
    assert_equal 0, matching_tickets.count
  end

  def test_tickets_for_subject_with_does_not_contain
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "help"
    create :automation_condition, conditionable: group, field: "subject", verb: "does_not_contain", value: "documentation"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_4
  end

  def test_tickets_for_body_with_contains
    @ticket_1.comments.description.first.update info: "Your refund is being processed."
    @ticket_2.comments.description.first.update info: "We are processing your refund."
    @ticket_3.comments.description.first.update info: "We are working on a resolution."
    @ticket_4.comments.description.first.update info: "Your final payment is done."
    @ticket_5.comments.description.first.update info: "Thanks for being in touch. Your ticket is move to closed since it was open for 2 years."

    group = create :automation_condition_group, :match_any, rule: @rule
    create :automation_condition, conditionable: group, field: "ticket.comments.description", verb: "contains", value: "refund"
    create :automation_condition, conditionable: group, field: "ticket.comments.description", verb: "contains", value: "resolution"

    matching_tickets = get_matching_tickets
    assert_equal 3, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
    assert_includes matching_tickets, @ticket_3
  end

  def test_tickets_for_email_with_is
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "requester.email", verb: "is", value: "aditya.varma@example.com"
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "refund"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
  end

  def test_tickets_for_email_with_is_not
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "requester.email", verb: "is_not", value: "aditya.varma@example.com"
    create :automation_condition, conditionable: group, field: "subject", verb: "does_not_contain", value: "issue"

    matching_tickets = get_matching_tickets
    assert_equal 2, matching_tickets.count
    assert_includes matching_tickets, @ticket_4
  end

  def test_tickets_for_email_with_contains
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "requester.email", verb: "contains", value: "aditya"
    create :automation_condition, conditionable: group, field: "subject", verb: "does_not_contain", value: "refund"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_2
  end

  def test_tickets_for_email_with_does_not_contain
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "requester.email", verb: "does_not_contain", value: "virat"
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "refund"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
  end

  def test_tickets_for_status_hours_open_with_is
    @ticket_1.update!(status: "open")
    @ticket_2.update!(status: "waiting_on_customer")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from New to Open",
      created_at: Time.current - 2.hours
    activity = create :activity, trackable: @ticket_2,
      key: "activity.ticket.update.status",
      action: "Status was changed from New to Waiting on Customer",
      created_at: Time.current - 2.hours

    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, :time_based, conditionable: group, field: "status.hours.open", verb: "is", value: "2"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
  end

  def test_tickets_for_status_hours_open_with_less_than
    @ticket_1.update(status: "open")
    @ticket_2.update(status: "open")

    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from New to Open",
      created_at: Time.current - 3.hours
    activity = create :activity, trackable: @ticket_2,
      key: "activity.ticket.update.status",
      action: "Status was changed from New to Open",
      created_at: Time.current - 5.hours

    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, :time_based, conditionable: group, field: "status.hours.open", verb: "less_than", value: "4"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
  end

  def test_tickets_for_status_hours_open_with_greater_than
    @ticket_1.update(status: "open")
    @ticket_2.update(status: "open")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from New to Open",
      created_at: Time.current - 5.hours
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from New to Open",
      created_at: Time.current - 2.hours

    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, :time_based, conditionable: group, field: "status.hours.open", verb: "greater_than", value: "4"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
  end

  def test_tickets_for_status_with_is
    @ticket_1.update(status: "waiting_on_customer")
    @ticket_2.update(status: "waiting_on_customer")
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "status", verb: "is", value: "waiting_on_customer"
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "refund"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
  end

  def test_tickets_for_status_with_is_not
    @ticket_1.update(status: "waiting_on_customer")
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "status", verb: "is_not", value: "waiting_on_customer"
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "help"

    matching_tickets = get_matching_tickets
    assert_equal 2, matching_tickets.count
    assert_includes matching_tickets, @ticket_4
  end

  def test_tickets_for_category_with_is
    @ticket_1.update(category: "Questions")
    @ticket_2.update(category: "Questions")
    @ticket_3.update(category: "Questions")
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "category", verb: "is", value: "Questions"
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "refund"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
  end

  def test_tickets_for_category_with_is_not
    @ticket_1.update(category: "Questions")
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "category", verb: "is_not", value: "Questions"
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "help"

    matching_tickets = get_matching_tickets
    assert_equal 2, matching_tickets.count
    assert_includes matching_tickets, @ticket_4
  end

  def test_tickets_for_priority_with_is
    @ticket_1.medium!
    @ticket_2.medium!
    @ticket_3.medium!
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "priority", verb: "is", value: 1
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "refund"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
  end

  def test_tickets_for_priority_with_is_not
    @ticket_1.medium!
    @ticket_2.high!
    @ticket_3.urgent!
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "priority", verb: "is_not", value: 0
    create :automation_condition, conditionable: group, field: "priority", verb: "is_not", value: 2

    matching_tickets = get_matching_tickets
    assert_equal 2, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
  end

  def test_tickets_for_priority_with_less_than
    @ticket_1.medium!
    @ticket_2.high!
    @ticket_3.urgent!
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "priority", verb: "less_than", value: 2
    create :automation_condition, conditionable: group, field: "priority", verb: "is_not", value: 0

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
  end

  def test_tickets_for_priority_with_greater_than
    @ticket_1.medium!
    @ticket_2.high!
    @ticket_3.urgent!
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "priority", verb: "greater_than", value: 1
    create :automation_condition, conditionable: group, field: "priority", verb: "is_not", value: 2

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_3
  end

  def test_tickets_for_agent_id_with_is
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "agent_id", verb: "is", value: @amit.id
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "refund"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
  end

  def test_tickets_for_agent_id_with_is_not
    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "agent_id", verb: "is_not", value: @amit.id
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "help"

    matching_tickets = get_matching_tickets
    assert_equal 2, matching_tickets.count
    assert_includes matching_tickets, @ticket_4
  end

  def test_tickets_for_created_at_with_during
    business_hour = create :business_hour, :weekend, organization: @organization
    last_saturday = Time.current.beginning_of_week.advance(days: -2, hours: 10)

    @ticket_1.update(created_at: last_saturday - 2.days)
    @ticket_2.update(created_at: last_saturday - 2.days)
    @ticket_3.update(created_at: last_saturday - 2.days)
    @ticket_4.update(created_at: last_saturday)
    @ticket_5.update(created_at: last_saturday - 5.hours)

    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "created_at", verb: "during", value: business_hour.id
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "help"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_4
  end

  def test_tickets_for_created_at_with_not_during
    business_hour = create :business_hour, :weekend, organization: @organization
    last_saturday = Time.current.beginning_of_week.advance(days: -2, hours: 10)

    @ticket_1.update(created_at: last_saturday - 2.days)
    @ticket_2.update(created_at: last_saturday - 2.days)
    @ticket_3.update(created_at: last_saturday - 2.days)
    @ticket_4.update(created_at: last_saturday)
    @ticket_5.update(created_at: last_saturday - 5.hours)

    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "created_at", verb: "not_during", value: business_hour.id
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "help"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_5
  end

  def test_tickets_for_created_at_for_any_time
    business_hour = create :business_hour, :weekend, organization: @organization

    group = create :automation_condition_group, :match_all, rule: @rule
    create :automation_condition, conditionable: group, field: "created_at", verb: "any_time", value: ""
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "help"

    matching_tickets = get_matching_tickets
    assert_equal 2, matching_tickets.count
  end

  def test_tickets_are_uniq
    @ticket_1.update subject: "I am expecting the refund."
    @ticket_1.comments.description.first.update info: "Can I expect my refund?"

    group = create :automation_condition_group, :match_any, rule: @rule
    create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "expect"
    create :automation_condition, conditionable: group, field: "ticket.comments.description", verb: "contains", value: "expect"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
  end

  def test_tickets_with_ticket_field_responses
    group = create :automation_condition_group, :match_any, rule: @rule

    ticket_field_1 = create :ticket_field, organization: @organization
    ticket_field_2 = create :ticket_field, :number, organization: @organization
    condition_1 = create :automation_condition, kind: :ticket_field, conditionable: group, field: ticket_field_1.id, verb: "is", value: "chrome"
    condition_2 = create :automation_condition, kind: :ticket_field, conditionable: group, field: ticket_field_2.id, verb: "is", value: "12"

    create :ticket_field_response, ticket_field: ticket_field_1, owner: @ticket_1, value: "Chrome"
    create :ticket_field_response, ticket_field: ticket_field_2, owner: @ticket_1, value: "12"

    matching_tickets = get_matching_tickets
    assert_equal 1, matching_tickets.count
  end

  private

    def get_matching_tickets
      ::Desk::Core::RuleTicketsFinder.new(@rule.reload).rule_matching_tickets
    end
end
