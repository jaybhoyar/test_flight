# frozen_string_literal: true

require "test_helper"

class Automation::ConditionCarrierTest < ActiveSupport::TestCase
  def test_that_display_value_is_correct_for_status
    organization = create :organization
    ticket_field = create :ticket_field, :system_status, organization: organization
    status = create :desk_ticket_status, :waiting_on_customer, organization: organization

    rule = create :automation_rule, organization: organization
    condition_group = create :automation_condition_group, rule: rule
    condition = create :automation_condition,
      field: "status",
      verb: "is",
      value: "waiting_on_customer",
      conditionable: condition_group

    carrier = get_carrier(condition)
    assert_equal "Waiting on Customer", carrier.display_value
  end

  def test_that_display_value_is_correct_for_priority
    condition = create :automation_condition, field: "priority", verb: "is", value: "2"

    carrier = get_carrier(condition)
    assert_equal "high", carrier.display_value
  end

  def test_that_display_value_is_correct_for_agent_id
    agent = create :user
    condition = create :automation_condition, field: "agent_id", verb: "is", value: agent.id

    carrier = get_carrier(condition)
    assert_equal agent.name, carrier.display_value
  end

  def test_that_display_value_is_correct_for_company_id
    company = create :company
    condition = create :automation_condition, field: "company_id", verb: "is", value: company.id

    carrier = get_carrier(condition)
    assert_equal company.name, carrier.display_value
  end

  def test_that_display_value_is_correct_for_group_id
    group = create :group
    condition = create :automation_condition, field: "group_id", verb: "is", value: group.id

    carrier = get_carrier(condition)
    assert_equal group.name, carrier.display_value
  end

  def test_that_display_value_is_nil_for_deleted_agent
    condition = create :automation_condition, field: "agent_id", verb: "is", value: "wrong_user_id"

    carrier = get_carrier(condition)
    assert_nil carrier.display_value
  end

  def test_that_display_value_is_correct_for_tag_id
    tag = create :ticket_tag
    condition = create :automation_condition, :tags, field: "tag_ids", verb: "contains_any_of", tag_ids: [tag.id]

    carrier = get_carrier(condition)
    assert_equal tag.name, carrier.display_value
  end

  def test_that_display_value_is_correct_for_created_at
    business_hour = create :business_hour
    condition = create :automation_condition, field: "created_at", verb: "during", value: business_hour.id

    carrier = get_carrier(condition)
    assert_equal business_hour.name, carrier.display_value
  end

  def test_that_display_value_is_nil_for_deleted_business_hours
    condition = create :automation_condition, field: "created_at", verb: "during", value: "wrong_business_hour_id"

    carrier = get_carrier(condition)
    assert_nil carrier.display_value
  end

  def test_that_display_value_is_correct_for_ticket_fields_with_dropdown
    ticket_field = create :ticket_field, :dropdown
    ticket_field_option = ticket_field.ticket_field_options.first
    condition = create :automation_condition, kind: :ticket_field, field: ticket_field.id, verb: "is",
      value: ticket_field_option.id

    carrier = get_carrier(condition)
    assert_equal ticket_field_option.name, carrier.display_value
  end

  def test_that_display_value_is_correct_for_others
    condition_1 = create :automation_condition, field: "subject", verb: "contains", value: "issue"

    assert_equal "issue", get_carrier(condition_1).display_value

    condition_2 = create :automation_condition, field: "email", verb: "contains", value: "@example.com"

    assert_equal "@example.com", get_carrier(condition_2).display_value
  end

  def test_that_display_value_is_correct_for_contains_any_of_all_of_and_none_of
    condition_1 = create :automation_condition, field: "ticket.comments.description", verb: "contains_any_of", value: "issue||task"
    assert_equal "issue, task", get_carrier(condition_1).display_value

    condition_2 = create :automation_condition, field: "ticket.comments.description", verb: "contains_all_of", value: "issue||task"
    assert_equal "issue, task", get_carrier(condition_2).display_value

    condition_3 = create :automation_condition, field: "ticket.comments.description", verb: "contains_none_of", value: "issue||task"
    assert_equal "issue, task", get_carrier(condition_3).display_value
  end

  def test_that_display_value_is_correct_for_submitter_role
    condition_1 = create :automation_condition, field: "submitter_role", verb: "is", value: nil
    assert_equal "Customer", get_carrier(condition_1).display_value

    role = create :organization_role, name: "Admin"
    condition_2 = create :automation_condition, field: "submitter_role", verb: "is", value: role.id
    assert_equal role.name, get_carrier(condition_2).display_value
  end

  private

    def get_carrier(condition)
      Automation::ConditionCarrier.new(condition)
    end
end
