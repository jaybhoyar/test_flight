# frozen_string_literal: true

require "test_helper"
class Desk::Core::TicketsFinder::TicketFieldsTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @rule = create :automation_rule, organization: @organization

    @condition_group = create :automation_condition_group, rule: @rule
    @ticket_1 = create :ticket, organization: @organization, subject: "When can I expect my refund?"
    @ticket_2 = create :ticket, organization: @organization, subject: "I am unable to use the application"
    @ticket_3 = create :ticket, organization: @organization, subject: "I am having issues with the plugin"
    @ticket_4 = create :ticket, organization: @organization, subject: "Where is help section in the app"

    @ticket_field_1 = create :ticket_field, organization: @organization
    @ticket_field_2 = create :ticket_field, :dropdown, organization: @organization
    @ticket_field_3 = create :ticket_field, :textarea, organization: @organization
    @ticket_field_4 = create :ticket_field, :number, organization: @organization
  end

  def test_tickets_for_ticket_fields
    create :ticket_field_response, ticket_field: @ticket_field_1, owner: @ticket_1, value: "Chrome 13.0.12"
    create :ticket_field_response, ticket_field: @ticket_field_1, owner: @ticket_2, value: "Safari 10.11.2"
    create :ticket_field_response, ticket_field: @ticket_field_1, owner: @ticket_3, value: "Firefox 11.212"
    create :ticket_field_response, ticket_field: @ticket_field_1, owner: @ticket_4, value: "TOR 123.123.123"

    condition = create :automation_condition, kind: :ticket_field, conditionable: @condition_group, field: @ticket_field_1.id, verb: "contains", value: "tor"
    assert_equal 1, get_query(condition).count
  end

  def test_tickets_with_is_for_dropdown
    option_1 = @ticket_field_2.ticket_field_options.first
    option_2 = create :ticket_field_option, ticket_field: @ticket_field_2, name: "Safari"
    option_3 = create :ticket_field_option, ticket_field: @ticket_field_2, name: "Firefox"
    option_4 = create :ticket_field_option, ticket_field: @ticket_field_2, name: "TOR"

    create :ticket_field_response, ticket_field: @ticket_field_2, owner: @ticket_1, ticket_field_option_id: option_1.id
    create :ticket_field_response, ticket_field: @ticket_field_2, owner: @ticket_2, ticket_field_option_id: option_2.id
    create :ticket_field_response, ticket_field: @ticket_field_2, owner: @ticket_3, ticket_field_option_id: option_3.id
    create :ticket_field_response, ticket_field: @ticket_field_2, owner: @ticket_4, ticket_field_option_id: option_4.id

    condition_2 = create :automation_condition, kind: :ticket_field, conditionable: @condition_group,
      field: @ticket_field_2.id, verb: "is", value: option_2.id
    assert_equal 1, get_query(condition_2).count
  end

  def test_tickets_with_contains_for_textarea
    create :ticket_field_response, ticket_field: @ticket_field_3, owner: @ticket_1, value: "I am using MacBook PRO 13 inch, 2019, Catalina"
    create :ticket_field_response, ticket_field: @ticket_field_3, owner: @ticket_2, value: "I am using Dell Inspiron with Windows 10, 2019"
    create :ticket_field_response, ticket_field: @ticket_field_3, owner: @ticket_3, value: "I am using Surface PRO, Windows 10, 2018"
    create :ticket_field_response, ticket_field: @ticket_field_3, owner: @ticket_4, value: "I am using MacBook PRO 13 inch, 2017, Montain Lion"

    condition_3 = create :automation_condition, kind: :ticket_field, conditionable: @condition_group, field: @ticket_field_3.id, verb: "contains", value: "MacBook"
    assert_equal 2, get_query(condition_3).count
  end

  def test_tickets_with_is_for_number
    create :ticket_field_response, ticket_field: @ticket_field_4, owner: @ticket_1, value: "25"
    create :ticket_field_response, ticket_field: @ticket_field_4, owner: @ticket_2, value: "10"
    create :ticket_field_response, ticket_field: @ticket_field_4, owner: @ticket_3, value: "15"
    create :ticket_field_response, ticket_field: @ticket_field_4, owner: @ticket_4, value: "20"

    condition_4 = create :automation_condition, kind: :ticket_field, conditionable: @condition_group, field: @ticket_field_4.id, verb: "is", value: "15"
    assert_equal 1, get_query(condition_4).count
  end

  def test_tickets_with_less_than_for_number
    create :ticket_field_response, ticket_field: @ticket_field_4, owner: @ticket_1, value: "25"
    create :ticket_field_response, ticket_field: @ticket_field_4, owner: @ticket_2, value: "10"
    create :ticket_field_response, ticket_field: @ticket_field_4, owner: @ticket_3, value: "15"
    create :ticket_field_response, ticket_field: @ticket_field_4, owner: @ticket_4, value: "20"

    condition_5 = create :automation_condition, kind: :ticket_field, conditionable: @condition_group, field: @ticket_field_4.id, verb: "less_than", value: "20"
    assert_equal 2, get_query(condition_5).count
  end

  def test_tickets_with_greater_than_for_number
    create :ticket_field_response, ticket_field: @ticket_field_4, owner: @ticket_1, value: "25"
    create :ticket_field_response, ticket_field: @ticket_field_4, owner: @ticket_2, value: "10"
    create :ticket_field_response, ticket_field: @ticket_field_4, owner: @ticket_3, value: "15"
    create :ticket_field_response, ticket_field: @ticket_field_4, owner: @ticket_4, value: "20"

    condition_6 = create :automation_condition, kind: :ticket_field, conditionable: @condition_group, field: @ticket_field_4.id, verb: "greater_than", value: "20"
    assert_equal 1, get_query(condition_6).count
  end

  private

    def get_query(condition)
      service = ::Desk::Core::TicketsFinder::TicketFields.new(
        condition.kind, condition.field, condition.verb,
        condition.value, condition.tag_ids)
      ::Ticket.joins(service.desk_ticket_fields_join).where(service.matching_ticket_predicate).distinct
    end
end
