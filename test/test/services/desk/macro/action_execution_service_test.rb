# frozen_string_literal: true

require "test_helper"

class Desk::Macro::ActionExecutionServiceTest < ActiveSupport::TestCase
  def setup
    @user = create :user
    @organization = @user.organization

    @macro = create :desk_macro_rule, :visible_to_all_agents, organization: @organization, name: "All rounder"
  end

  def test_set_tags
    tag_1 = create :ticket_tag, name: "Tag 1", organization: @organization
    tag_2 = create :ticket_tag, name: "Tag 2", organization: @organization
    tag_3 = create :ticket_tag, name: "Tag 3", organization: @organization

    ticket = create :ticket, organization: @organization
    ticket.update_tags([tag_1])

    action = create :desk_macro_action, rule: @macro, name: "set_tags", tag_ids: [tag_2.id, tag_3.id]

    assert_equal ["Tag 1"], ticket.tags.pluck(:name).sort

    service = Desk::Macro::ActionExecutionService.new(action, ticket)
    service.run

    assert_equal ["Tag 2", "Tag 3"], ticket.reload.tags.pluck(:name).sort
  end

  def test_add_tags
    tag_1 = create :ticket_tag, name: "Tag 1", organization: @organization
    tag_2 = create :ticket_tag, name: "Tag 2", organization: @organization
    tag_3 = create :ticket_tag, name: "Tag 3", organization: @organization

    ticket = create :ticket, organization: @organization
    ticket.update_tags([tag_1])

    action = create :desk_macro_action, rule: @macro, name: "add_tags", tag_ids: [tag_2.id, tag_3.id]

    assert_equal ["Tag 1"], ticket.tags.pluck(:name).sort

    service = Desk::Macro::ActionExecutionService.new(action, ticket)
    service.run

    assert_equal ["Tag 1", "Tag 2", "Tag 3"], ticket.reload.tags.pluck(:name).sort
  end

  def test_remove_tags
    tag_1 = create :ticket_tag, name: "Tag 1", organization: @organization
    tag_2 = create :ticket_tag, name: "Tag 2", organization: @organization
    tag_3 = create :ticket_tag, name: "Tag 3", organization: @organization

    ticket = create :ticket, organization: @organization
    ticket.update_tags([tag_1, tag_2])

    action = create :desk_macro_action, rule: @macro, name: "remove_tags", tag_ids: [tag_2.id, tag_3.id]

    assert_equal ["Tag 1", "Tag 2"], ticket.tags.pluck(:name).sort

    service = Desk::Macro::ActionExecutionService.new(action, ticket)
    service.run

    assert_equal ["Tag 1"], ticket.reload.tags.pluck(:name).sort
  end

  def test_change_status
    ticket = create :ticket, organization: @organization, status: "Open"

    action = create :desk_macro_action, rule: @macro, name: "change_status", value: "Closed"

    assert_equal "Open", ticket.status

    service = Desk::Macro::ActionExecutionService.new(action, ticket)
    service.run

    assert_equal "Closed", ticket.reload.status
  end

  def test_change_priority
    ticket = create :ticket, organization: @organization, priority: "low"

    action = create :desk_macro_action, rule: @macro, name: "change_priority", value: "urgent"

    assert_equal "low", ticket.priority

    service = Desk::Macro::ActionExecutionService.new(action, ticket)
    service.run

    assert_equal "urgent", ticket.reload.priority
  end

  def test_assign_group
    group_1 = create :group, name: "Billing", organization: @organization
    group_2 = create :group, name: "Payments", organization: @organization
    ticket = create :ticket, organization: @organization, group: group_1

    action = create :desk_macro_action, rule: @macro, name: "assign_group", actionable: group_2

    assert_equal group_1.id, ticket.group_id

    service = Desk::Macro::ActionExecutionService.new(action, ticket)
    service.run

    assert_equal group_2.id, ticket.reload.group_id
  end

  def test_assign_agent
    ticket = create :ticket, organization: @organization
    action = create :desk_macro_action, rule: @macro, name: "assign_agent", actionable: @user

    assert_nil ticket.agent_id

    service = Desk::Macro::ActionExecutionService.new(action, ticket)
    service.run

    assert_equal @user.id, ticket.reload.agent_id
  end
end
