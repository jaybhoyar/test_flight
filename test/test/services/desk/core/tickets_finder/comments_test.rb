# frozen_string_literal: true

require "test_helper"
class Desk::Core::TicketsFinder::CommentsTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @rule = create :automation_rule, organization: @organization
    create_tickets
  end

  def test_tickets_for_subject_or_description_with_contains
    @ticket_1.comments.description.first.update info: "Your refund is being processed."
    @ticket_2.comments.description.first.update info: "We are processing your refund."
    @ticket_3.comments.description.first.update info: "We are working on a resolution."

    condition = create :automation_condition, field: "subject_or_description", verb: "contains", value: "resolution"

    matching_tickets = get_query(condition)
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_3
  end

  def test_tickets_for_subject_or_description_with_does_not_contain
    @ticket_1.comments.description.first.update info: "Your refund is being processed."
    @ticket_2.comments.description.first.update info: "We are processing your refund."
    @ticket_3.comments.description.first.update info: "We are working on a resolution."
    condition = create :automation_condition, field: "subject_or_description", verb: "does_not_contain", value: "refund"

    matching_tickets = get_query(condition)
    assert_equal 3, matching_tickets.count
    assert_includes matching_tickets, @ticket_3
  end

  def test_tickets_for_description_with_contains
    @ticket_1.comments.description.first.update info: "Your refund is being processed."
    @ticket_2.comments.description.first.update info: "We are processing your refund."
    @ticket_3.comments.description.first.update info: "We are working on a resolution."
    create :comment, ticket: @ticket_3, info: "Your refund is being processed."

    condition = create :automation_condition, field: "ticket.comments.description", verb: "contains", value: "refund"

    matching_tickets = get_query(condition)
    assert_equal 2, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
  end

  def test_tickets_for_description_with_contains_any_of
    @ticket_1.comments.description.first.update info: "We are working on a resolution."
    @ticket_2.comments.description.first.update info: "Your refund will be initiated tomorrow."
    @ticket_3.comments.description.first.update info: "We expect your response to work towards helping you."
    create :comment, ticket: @ticket_3, info: "Your refund is being processed."

    condition = create :automation_condition, field: "ticket.comments.description", verb: "contains_any_of", value: "refund||help"

    matching_tickets = get_query(condition)
    assert_equal 2, matching_tickets.count
    assert_includes matching_tickets, @ticket_2
    assert_includes matching_tickets, @ticket_3
  end

  def test_tickets_for_description_with_contains_all_of
    @ticket_1.comments.description.first.update info: "We are working on a resolution."
    @ticket_2.comments.description.first.update info: "Your refund will be initiated tomorrow."
    @ticket_3.comments.description.first.update info: "We expect your response to work towards helping you tomorrow."
    create :comment, ticket: @ticket_3, info: "Your refund is being processed tomorrow."

    condition = create :automation_condition, field: "ticket.comments.description", verb: "contains_all_of", value: "refund||tomorrow"

    matching_tickets = get_query(condition)
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_2
  end

  def test_tickets_for_description_with_contains_none_of
    @ticket_1.comments.description.first.update info: "We are working on a resolution."
    @ticket_2.comments.description.first.update info: "Your refund will be initiated tomorrow."
    @ticket_3.comments.description.first.update info: "We expect your response to work towards helping you tomorrow."
    @ticket_4.comments.description.first.update info: "I need my refund"
    @ticket_5.comments.description.first.update info: "Something that contains \"tomorrow\""

    create :comment, ticket: @ticket_3, info: "Your refund is being processed tomorrow."

    condition = create :automation_condition, field: "ticket.comments.description", verb: "contains_none_of", value: "refund||tomorrow"

    matching_tickets = get_query(condition)
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
  end

  def test_tickets_for_latest_comment_with_contains
    @ticket_1.comments.description.first.update info: "We are working on a resolution."
    create :comment, ticket: @ticket_1, info: "Your refund is being processed."
    create :comment, ticket: @ticket_2, info: "We are processing your refund."
    create :comment, ticket: @ticket_3, info: "We are working on a resolution."

    condition = create :automation_condition, field: "ticket.comments.latest", verb: "contains", value: "working"

    matching_tickets = get_query(condition)
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_3
  end

  def test_tickets_for_latest_comment_with_does_not_contain
    @ticket_1.comments.description.first.update info: "We are working on a resolution."
    create :comment, ticket: @ticket_1, info: "Your refund is being processed."
    create :comment, ticket: @ticket_2, info: "We are processing your refund."
    create :comment, ticket: @ticket_3, info: "We are working on a resolution."

    condition = create :automation_condition, field: "ticket.comments.latest", verb: "does_not_contain", value: "refund"

    matching_tickets = get_query(condition)
    assert_equal 3, matching_tickets.count
    assert_includes matching_tickets, @ticket_3
  end

  def test_tickets_for_latest_comment_with_contains_any_of
    create :comment, ticket: @ticket_1, info: "Your refund is being processed."
    create :comment, ticket: @ticket_2, info: "We are processing your refund."
    create :comment, ticket: @ticket_3, info: "We are working on a resolution."

    condition = create :automation_condition, field: "ticket.comments.latest", verb: "contains_any_of", value: "refund||working"

    matching_tickets = get_query(condition)
    assert_equal 3, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
    assert_includes matching_tickets, @ticket_2
    assert_includes matching_tickets, @ticket_3
  end

  def test_tickets_for_latest_comment_with_contains_all_of
    create :comment, ticket: @ticket_1, info: "Your refund is being processed."
    create :comment, ticket: @ticket_2, info: "We are processing your refund."
    create :comment, ticket: @ticket_3, info: "We are working on a resolution."

    condition = create :automation_condition, field: "ticket.comments.latest", verb: "contains_all_of", value: "working||resolution"

    matching_tickets = get_query(condition)
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_3
  end

  def test_tickets_for_latest_comment_with_contains_none_of
    create :comment, ticket: @ticket_1, info: "Your refund is being processed."
    create :comment, ticket: @ticket_2, info: "We are processing your refund."
    create :comment, ticket: @ticket_3, info: "We are working on a resolution."

    condition = create :automation_condition, field: "ticket.comments.latest", verb: "contains_none_of", value: "working||being"

    matching_tickets = get_query(condition)
    assert_equal 3, matching_tickets.count
    assert_includes matching_tickets, @ticket_2
  end

  def test_tickets_for_any_comment_with_contains
    @ticket_1.comments.description.first.update info: "Your refund is being processed."
    create :comment, ticket: @ticket_2, info: "We are processing your refund."
    create :comment, ticket: @ticket_3, info: "We are working on a resolution."

    condition = create :automation_condition, field: "ticket.comments.any", verb: "contains", value: "refund"

    matching_tickets = get_query(condition)

    assert_equal 2, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
    assert_includes matching_tickets, @ticket_2
  end

  def test_tickets_for_any_comment_with_does_not_contain
    @ticket_1.comments.description.first.update info: "Your refund is being processed."
    create :comment, ticket: @ticket_2, info: "We are processing your refund."
    create :comment, ticket: @ticket_3, info: "We are working on a resolution."
    create :comment, ticket: @ticket_4, info: "Something with \"refund\""
    @ticket_5.comments.description.first.update info: "refund refund refund"

    condition = create :automation_condition, field: "ticket.comments.any", verb: "does_not_contain", value: "refund"

    matching_tickets = get_query(condition)
    assert_equal 1, matching_tickets.count
    assert_includes matching_tickets, @ticket_3
  end

  def test_tickets_for_any_comment_with_contains_any_of
    create :comment, ticket: @ticket_1, info: "Your refund is being processed."
    create :comment, ticket: @ticket_2, info: "We are processing your refund."
    create :comment, ticket: @ticket_3, info: "We are working on a resolution."

    condition = create :automation_condition, field: "ticket.comments.any", verb: "contains_any_of", value: "refund||working"

    matching_tickets = get_query(condition)
    assert_equal 3, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
    assert_includes matching_tickets, @ticket_2
    assert_includes matching_tickets, @ticket_3
  end

  def test_tickets_for_any_comment_with_contains_all_of
    create :comment, ticket: @ticket_1, info: "Your refund is being processed."
    create :comment, ticket: @ticket_2, info: "We are processing your refund."
    create :comment, ticket: @ticket_3, info: "refund"
    create :comment, ticket: @ticket_3, info: "process"

    condition = create :automation_condition, field: "ticket.comments.any", verb: "contains_all_of", value: "refund||process"

    matching_tickets = get_query(condition)
    assert_equal 2, matching_tickets.count
    assert_includes matching_tickets, @ticket_1
    assert_includes matching_tickets, @ticket_2
  end

  def test_tickets_for_any_comment_with_contains_none_of
    create :comment, ticket: @ticket_1, info: "Your refund is being processed."
    create :comment, ticket: @ticket_2, info: "We are processing your refund."
    create :comment, ticket: @ticket_3, info: "We are working on a resolution."

    condition = create :automation_condition, field: "ticket.comments.any", verb: "contains_none_of", value: "refund||working"

    matching_tickets = get_query(condition)
    assert_equal 2, matching_tickets.count
    assert_includes matching_tickets, @ticket_4
    assert_includes matching_tickets, @ticket_5
  end

  private

    def get_query(condition)
      service = ::Desk::Core::TicketsFinder::Comments.new(
        condition.kind, condition.field, condition.verb,
        condition.value, condition.tag_ids)
      ::Ticket.left_outer_joins(:taggings).where(service.matching_ticket_predicate).distinct
    end

    def create_tickets
      @ticket_1 = create :ticket, :with_desc, organization: @organization, subject: "When can I expect my refund?"
      @ticket_2 = create :ticket, :with_desc, organization: @organization, subject: "I am unable to use the application"
      @ticket_3 = create :ticket, :with_desc, organization: @organization, subject: "How to setup the plugin?"
      @ticket_4 = create :ticket, :with_desc, organization: @organization, subject: "Ticket 4"
      @ticket_5 = create :ticket, :with_desc, organization: @organization, subject: "Ticket 5"
    end
end
