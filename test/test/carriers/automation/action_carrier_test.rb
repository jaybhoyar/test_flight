# frozen_string_literal: true

require "test_helper"

class Automation::ActionCarrierTest < ActiveSupport::TestCase
  def test_that_display_value_is_correct_for_status
    organization = create :organization

    ticket_field = create :ticket_field, :system_status, organization: organization
    status = create :desk_ticket_status, :closed, organization: organization

    rule = create :automation_rule, organization: organization
    action = create :automation_action, name: "change_ticket_status", status: "closed", rule: rule

    carrier = Automation::ActionCarrier.new(action)
    assert_equal "Closed", carrier.display_value
  end

  def test_that_display_value_is_correct_for_tags
    tag_1 = create :ticket_tag, name: "Alpha"
    tag_2 = create :ticket_tag, name: "Beta"
    action = create :automation_action, name: "set_tags", tag_ids: [tag_1.id, tag_2.id]
    carrier = Automation::ActionCarrier.new(action)
    assert_equal "Alpha, Beta", carrier.display_value
  end

  def test_that_display_value_is_correct_for_agent
    agent = create :user
    action = create :automation_action, name: "assign_agent", actionable: agent
    carrier = Automation::ActionCarrier.new(action)
    assert_equal agent.name, carrier.display_value
  end

  def test_that_display_value_is_correct_for_email_to_agent
    agent = create :user
    action = create :automation_action, name: "email_to_agent", actionable: agent,
      subject: "Your refund will done asap.",
      body: "No need to worry."
    carrier = Automation::ActionCarrier.new(action)
    assert_equal agent.name, carrier.display_value
  end

  def test_that_display_value_is_correct_for_email_to
    agent = create :user
    action = create :automation_action, name: "email_to", value: "rohit@example.com, ishit@example.com",
      subject: "Your refund will done asap.",
      body: "No need to worry."
    carrier = Automation::ActionCarrier.new(action)
    assert_equal "rohit@example.com, ishit@example.com", carrier.display_value
  end

  def test_that_display_value_is_correct_for_assign_group
    group = create :group
    action = create :automation_action, name: "assign_group", actionable: group
    carrier = Automation::ActionCarrier.new(action)
    assert_equal group.name, carrier.display_value
  end

  def test_that_display_value_is_correct_for_task_list
    list = create :desk_task_list
    action = create :automation_action, name: "assign_group", actionable: list
    carrier = Automation::ActionCarrier.new(action)
    assert_equal list.name, carrier.display_value
  end
end
