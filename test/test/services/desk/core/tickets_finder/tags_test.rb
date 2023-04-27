# frozen_string_literal: true

require "test_helper"
class Desk::Core::TicketsFinder::TagsTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @rule = create :automation_rule, organization: @organization
  end

  def test_matching_ticket_predicate_with_contains_any_of
    create_tickets

    condition = create :automation_condition, :tags, conditionable: @rule, field: "tag_ids", verb: "contains_any_of",
      tag_ids: [@tag_1.id, @tag_2.id]
    assert_equal 3, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_contains_all_of
    create_tickets

    condition = create :automation_condition, :tags, conditionable: @rule, field: "tag_ids", verb: "contains_all_of",
      tag_ids: [@tag_1.id, @tag_2.id]
    assert_equal 1, get_query(condition).count
  end

  def test_matching_ticket_predicate_with_contains_none_of
    create_tickets

    condition = create :automation_condition, :tags, conditionable: @rule, field: "tag_ids", verb: "contains_none_of",
      tag_ids: [@tag_1.id, @tag_2.id]
    assert_equal 2, get_query(condition).count
  end

  private

    def get_query(condition)
      service = ::Desk::Core::TicketsFinder::Tags.new(
        condition.kind, condition.field, condition.verb, condition.value,
        condition.tag_ids)
      ::Ticket.left_outer_joins(:taggings).where(service.matching_ticket_predicate).distinct
    end

    def create_tickets
      @ticket_1 = create :ticket, organization: @organization, subject: "When can I expect my refund?"
      @ticket_2 = create :ticket, organization: @organization, subject: "I am unable to use the application"
      @ticket_3 = create :ticket, organization: @organization, subject: "How to setup the plugin?"
      @ticket_4 = create :ticket, organization: @organization, subject: "Ticket 4"
      @ticket_5 = create :ticket, organization: @organization, subject: "Ticket 5"

      @tag_1 = create :ticket_tag, organization: @organization
      @tag_2 = create :ticket_tag, organization: @organization
      @tag_3 = create :ticket_tag, organization: @organization
      @tag_4 = create :ticket_tag, organization: @organization

      @ticket_1.update_tags([@tag_1, @tag_2])
      @ticket_2.update_tags([@tag_2])
      @ticket_3.update_tags([@tag_1])
      @ticket_4.update_tags([@tag_3, @tag_4])
    end
end
