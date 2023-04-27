# frozen_string_literal: true

require "test_helper"
class Desk::Core::ConditionTicketsFinderTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @rule = create :automation_rule, organization: @organization
    @condition_group = create :automation_condition_group, rule: @rule
    @agent_role = create :organization_role_agent, organization: @organization
    @admin_role = create :organization_role_admin, organization: @organization

    company_a = create :company, name: "Wayne Corp", organization: @organization
    company_b = create :company, name: "Wayne Enterprizes", organization: @organization

    @group_1 = create :group, organization: @organization, name: "Sales"
    @group_2 = create :group, organization: @organization, name: "Marketing"

    @customer_jake = create :user,
      company: company_b,
      email: "jake@example.com",
      organization: @organization,
      role: nil

    @aditya = create :user,
      company: company_a, email: "aditya.varma@example.com",
      organization: @organization,
      role: nil

    @rohit = create :user,
      company: company_b, email: "rohit.sharma@example.com",
      organization: @organization,
      role: @admin_role

    virat = create :user,
      company: company_a, email: "virat.shetty@example.com",
      organization: @organization,
      role: @agent_role

    @agent_amit = create :user,
      email: "amit.mehta@example.com", organization: @organization,
      available_for_desk: false,
      role: @agent_role

    @agent_atish = create :user,
      email: "atish.baji@example.com",
      organization: @organization,
      role: @agent_role

    @ticket_1 = create :ticket, :with_desc, organization: @organization, group: @group_1, requester: @aditya, submitter: @aditya, agent: @agent_amit, subject: "When can I expect my refund?"
    @ticket_2 = create :ticket, :with_desc, organization: @organization, group: @group_1, requester: @aditya, submitter: @rohit, agent: @agent_amit, subject: "I am unable to use the application"
    @ticket_3 = create :ticket, :with_desc, organization: @organization, group: @group_2, requester: @rohit, submitter: @rohit, agent: @agent_atish, subject: "I am having issues with the plugin"
    @ticket_4 = create :ticket, :with_desc, organization: @organization, group: nil, requester: virat, submitter: @agent_amit, agent: @agent_atish, subject: "Where is help section in the app"
    @ticket_5 = create :ticket, :with_desc, organization: @organization, group: nil, requester: virat, submitter: virat, agent: @agent_atish, subject: "How to read the documentation"
  end

  def test_tickets_for_subject_with_contains
    condition_1 = create :automation_condition, conditionable: @condition_group, field: "subject", verb: "contains", value: "refund"

    matching_tickets = get_matching_tickets_for(condition_1)
    assert_equal 1, matching_tickets.count

    condition_2 = create :automation_condition, conditionable: @condition_group, field: "subject", verb: "does_not_contain", value: "help"

    matching_tickets = get_matching_tickets_for(condition_2)
    assert_equal 4, matching_tickets.count
  end

  def test_tickets_for_subject_or_description_with_contains
    @ticket_1.comments.description.first.update info: "Your refund is being processed."
    @ticket_2.comments.description.first.update info: "We are processing your refund."
    @ticket_3.comments.description.first.update info: "We are working on a resolution."

    condition_1 = create :automation_condition, conditionable: @condition_group, field: "subject_or_description", verb: "contains", value: "resolution"

    matching_tickets = get_matching_tickets_for(condition_1)
    assert_equal 1, matching_tickets.count

    condition_2 = create :automation_condition, conditionable: @condition_group, field: "subject_or_description", verb: "does_not_contain", value: "refund"

    matching_tickets = get_matching_tickets_for(condition_2)
    assert_equal 3, matching_tickets.count
  end

  def test_tickets_for_description_with_contains_any_of
    @ticket_1.comments.description.first.update info: "We are working on a resolution."
    @ticket_2.comments.description.first.update info: "Your refund will be initiated tomorrow."
    @ticket_3.comments.description.first.update info: "We expect your response to work towards helping you."
    create :comment, ticket: @ticket_3, info: "Your refund is being processed."

    condition = create :automation_condition, conditionable: @condition_group, field: "ticket.comments.description", verb: "contains_any_of", value: "refund||help"

    matching_tickets = get_matching_tickets_for(condition)
    assert_equal 2, matching_tickets.count
  end

  def test_tickets_for_comments
    create :comment, ticket: @ticket_1, info: "Your refund is being processed."
    create :comment, ticket: @ticket_2, info: "We are processing your refund."
    create :comment, ticket: @ticket_3, info: "We are working on a resolution."

    condition_contains_all_of = create :automation_condition, conditionable: @condition_group, field: "ticket.comments.latest", verb: "contains_all_of", value: "working||resolution"
    matching_tickets = get_matching_tickets_for(condition_contains_all_of)
    assert_equal 1, matching_tickets.count

    condition_contains_none_of = create :automation_condition, conditionable: @condition_group, field: "ticket.comments.any", verb: "contains_none_of", value: "refund||working"
    matching_tickets = get_matching_tickets_for(condition_contains_none_of)
    assert_equal 2, matching_tickets.count
  end

  def test_tickets_for_email_field
    condition_is = create :automation_condition, conditionable: @condition_group, field: "requester.email", verb: "is", value: "aditya.varma@example.com"
    matching_tickets = get_matching_tickets_for(condition_is)
    assert_equal 2, matching_tickets.count

    condition_is_not = create :automation_condition, conditionable: @condition_group, field: "requester.email", verb: "is_not", value: "aditya.varma@example.com"
    matching_tickets = get_matching_tickets_for(condition_is_not)
    assert_equal 3, matching_tickets.count

    condition_starts_with = create :automation_condition, conditionable: @condition_group, field: "requester.email", verb: "starts_with", value: "aditya"
    matching_tickets = get_matching_tickets_for(condition_starts_with)
    assert_equal 2, matching_tickets.count

    condition_ends_with = create :automation_condition, conditionable: @condition_group, field: "requester.email", verb: "ends_with", value: "shetty@example.com"
    matching_tickets = get_matching_tickets_for(condition_ends_with)
    assert_equal 2, matching_tickets.count

    condition_contains = create :automation_condition, conditionable: @condition_group, field: "requester.email", verb: "contains", value: "aditya"
    matching_tickets = get_matching_tickets_for(condition_contains)
    assert_equal 2, matching_tickets.count

    condition_does_not_contain = create :automation_condition, conditionable: @condition_group, field: "requester.email", verb: "does_not_contain", value: "virat"
    matching_tickets = get_matching_tickets_for(condition_does_not_contain)
    assert_equal 3, matching_tickets.count
  end

  def test_tickets_for_subject
    condition_starts_with = create :automation_condition, conditionable: @condition_group, field: "subject", verb: "starts_with", value: "I am"
    matching_tickets = get_matching_tickets_for(condition_starts_with)
    assert_equal 2, matching_tickets.count

    condition_ends_with = create :automation_condition, conditionable: @condition_group, field: "subject", verb: "ends_with", value: "the app"
    matching_tickets = get_matching_tickets_for(condition_ends_with)
    assert_equal 1, matching_tickets.count
  end

  def test_tickets_for_status_hours_open_with_is
    @ticket_1.update(status: "open")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from New to Open",
      created_at: Time.current - 2.hours

    condition = create :automation_condition, :time_based, conditionable: @condition_group, field: "status.hours.open", verb: "is", value: "2"

    matching_tickets = get_matching_tickets_for(condition)
    assert_equal 1, matching_tickets.count
  end

  def test_tickets_for_status_hours_open_with_less_than
    @ticket_1.update(status: "open")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from New to Open",
      created_at: Time.current - 3.hours

    condition = create :automation_condition, :time_based, conditionable: @condition_group, field: "status.hours.open", verb: "less_than", value: "4"

    matching_tickets = get_matching_tickets_for(condition)
    assert_equal 1, matching_tickets.count
  end

  def test_tickets_for_status_hours_open_with_greater_than
    @ticket_1.update(status: "open")
    activity = create :activity, trackable: @ticket_1,
      key: "activity.ticket.update.status",
      action: "Status was changed from New to Open",
      created_at: Time.current - 5.hours

    condition = create :automation_condition, :time_based, conditionable: @condition_group, field: "status.hours.open", verb: "greater_than", value: "4"

    matching_tickets = get_matching_tickets_for(condition)
    assert_equal 1, matching_tickets.count
  end

  def test_tickets_for_status
    @ticket_1.update(status: "waiting_on_customer")

    condition = create :automation_condition, conditionable: @condition_group, field: "status", verb: "is", value: "waiting_on_customer"
    matching_tickets = get_matching_tickets_for(condition)
    assert_equal 1, matching_tickets.count

    condition = create :automation_condition, conditionable: @condition_group, field: "status", verb: "is_not", value: "waiting_on_customer"
    matching_tickets = get_matching_tickets_for(condition)
    assert_equal 4, matching_tickets.count
  end

  def test_tickets_for_category
    @ticket_1.update(category: "Questions")

    condition_is = create :automation_condition, conditionable: @condition_group, field: "category", verb: "is", value: "Questions"
    assert_equal 1, get_matching_tickets_for(condition_is).count

    condition_is_not = create :automation_condition, conditionable: @condition_group, field: "category", verb: "is_not", value: "Questions"
    assert_equal 4, get_matching_tickets_for(condition_is_not).count
  end

  def test_tickets_for_priority
    @ticket_1.medium!

    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "priority",
      verb: "is",
      value: 1
    assert_equal 1, get_matching_tickets_for(condition).count

    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "priority",
      verb: "is_not",
      value: 0
    assert_equal 1, get_matching_tickets_for(condition).count

    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "priority",
      verb: "less_than",
      value: 1
    assert_equal 4, get_matching_tickets_for(condition).count

    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "priority",
      verb: "greater_than",
      value: 0
    assert_equal 1, get_matching_tickets_for(condition).count
  end

  def test_tickets_for_agent_id
    condition_is = create :automation_condition,
      conditionable: @condition_group,
      field: "agent_id",
      verb: "is",
      value: @agent_amit.id
    assert_equal 2, get_matching_tickets_for(condition_is).count

    condition_is_not = create :automation_condition,
      conditionable: @condition_group,
      field: "agent_id",
      verb: "is_not",
      value: @agent_amit.id
    assert_equal 3, get_matching_tickets_for(condition_is_not).count

    create :ticket, organization: @organization, subject: "This ticket will never have an agent."
    condition_unassigned = create :automation_condition,
      conditionable: @condition_group,
      field: "agent_id",
      verb: "is",
      value: nil
    assert_equal 1, get_matching_tickets_for(condition_unassigned).count

    condition_not_unassigned = create :automation_condition,
      conditionable: @condition_group,
      field: "agent_id",
      verb: "is_not",
      value: nil
    assert_equal 5, get_matching_tickets_for(condition_not_unassigned).count
  end

  def test_tickets_for_group_id
    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "group_id",
      verb: "is",
      value: @group_1.id
    assert_equal 2, get_matching_tickets_for(condition).count

    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "group_id",
      verb: "is_not",
      value: @group_1.id
    assert_equal 1, get_matching_tickets_for(condition).count

    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "group_id",
      verb: "is",
      value: nil
    assert_equal 2, get_matching_tickets_for(condition).count

    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "group_id",
      verb: "is_not",
      value: nil
    assert_equal 3, get_matching_tickets_for(condition).count
  end

  def test_tickets_for_created_at
    business_hour = create :business_hour, :weekend, organization: @organization
    last_saturday = Time.current.beginning_of_week.advance(days: -2, hours: 12)

    @ticket_1.update(created_at: last_saturday)
    @ticket_2.update(created_at: last_saturday - 4.hours)
    @ticket_3.update(created_at: last_saturday + 10.hours)
    @ticket_4.update(created_at: last_saturday - 2.days)
    @ticket_5.update(created_at: last_saturday - 2.days)

    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "created_at",
      verb: "during",
      value: business_hour.id
    assert_equal 1, get_matching_tickets_for(condition).count

    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "created_at",
      verb: "not_during",
      value: business_hour.id
    matching_tickets = get_matching_tickets_for(condition)
    assert_equal 4, matching_tickets.count
    assert_not_includes matching_tickets, @ticket_1

    condition = create :automation_condition, conditionable: @condition_group, field: "created_at", verb: "any_time", value: ""
    assert_equal 5, get_matching_tickets_for(condition).count
  end

  def test_tickets_for_submitter_role
    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "submitter_role",
      verb: "is",
      value: @aditya.organization_role_id
    assert_equal 1, get_matching_tickets_for(condition).count

    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "submitter_role",
      verb: "is",
      value: @rohit.organization_role_id
    assert_equal 2, get_matching_tickets_for(condition).distinct.count

    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "submitter_role",
      verb: "is_not",
      value: @customer_jake.organization_role_id
    assert_equal 4, get_matching_tickets_for(condition).count

    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "submitter_role",
      verb: "is_not",
      value: @agent_amit.organization_role_id
    assert_equal 2, get_matching_tickets_for(condition).count
  end

  def test_tickets_for_ticket_fields
    ticket_field = create :ticket_field, :number, organization: @organization

    create :ticket_field_response, ticket_field: ticket_field, owner: @ticket_1, value: "25"
    create :ticket_field_response, ticket_field: ticket_field, owner: @ticket_2, value: "10"
    create :ticket_field_response, ticket_field: ticket_field, owner: @ticket_3, value: "15"
    create :ticket_field_response, ticket_field: ticket_field, owner: @ticket_4, value: "20"

    # Matching with is for number
    condition_1 = create :automation_condition, kind: :ticket_field, conditionable: @condition_group, field: ticket_field.id, verb: "is", value: "15"
    matching_tickets_1 = get_matching_tickets_for(condition_1)

    assert_equal 1, matching_tickets_1.count

    # Matching with less_than for number
    condition_2 = create :automation_condition, kind: :ticket_field, conditionable: @condition_group, field: ticket_field.id, verb: "less_than", value: "20"
    matching_tickets_2 = get_matching_tickets_for(condition_2)

    assert_equal 2, matching_tickets_2.count

    # Matching with greater_than for number
    condition_3 = create :automation_condition, kind: :ticket_field, conditionable: @condition_group, field: ticket_field.id, verb: "greater_than", value: "20"
    matching_tickets_3 = get_matching_tickets_for(condition_3)

    assert_equal 1, matching_tickets_3.count
  end

  def test_matching_tickets_for_tag_ids
    ticket_6 = create :ticket, subject: "ticket 6"

    tag_1 = create :ticket_tag, organization: @organization
    tag_2 = create :ticket_tag, organization: @organization
    tag_3 = create :ticket_tag, organization: @organization

    @ticket_1.update_tags([tag_1, tag_2])
    @ticket_2.update_tags([tag_2, tag_3])
    @ticket_3.update_tags([tag_1])

    condition = create :automation_condition, :tags,
      conditionable: @condition_group,
      field: "tag_ids",
      verb: "contains_none_of",
      tag_ids: [tag_1.id, tag_2.id]
    assert_equal 2, get_matching_tickets_for(condition).count
  end

  def test_tickets_with_company
    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "company_id",
      verb: "is",
      value: @aditya.company_id
    assert_equal 4, get_matching_tickets_for(condition).count

    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "company_id",
      verb: "is_not",
      value: @aditya.company_id
    assert_equal 1, get_matching_tickets_for(condition).count
  end

  def test_tickets_with_agent_ooo
    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "agent.available_for_desk",
      verb: "is",
      value: "false"
    assert_equal 2, get_matching_tickets_for(condition).count

    condition = create :automation_condition,
      conditionable: @condition_group,
      field: "agent.available_for_desk",
      verb: "is",
      value: "true"
    assert_equal 3, get_matching_tickets_for(condition).count
  end

  private

    def get_matching_tickets_for(condition)
      ::Desk::Core::ConditionTicketsFinder.new(
        condition.kind, condition.field, condition.verb, condition.value,
        condition.tag_ids).matching_tickets_for(@organization)
    end
end
