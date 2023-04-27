# frozen_string_literal: true

require "test_helper"
class Desk::Automation::Actions::AssignAgentServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @agent_role = create :organization_role_agent, organization: @organization
    @user_1 = create :user, organization: @organization,
      role: @agent_role
    @user_2 = create :user, organization: @organization,
      role: @agent_role
    @user_3 = create :user, organization: @organization,
      role: @agent_role
    @user_4 = create :user, organization: @organization,
      role: @agent_role, continue_assigning_tickets: false

    rule = create :automation_rule, organization: @organization
    @round_robin = create :automation_action, name: "assign_agent_round_robin", rule: rule
    @load_balanced = create :automation_action, name: "assign_agent_load_balanced", rule:
  end

  def test_assign_agent_round_robin
    ticket = create :ticket, organization: @organization, group: nil
    Desk::Automation::Actions::AssignAgentService.new(@round_robin, ticket).run_round_robin
    assert_equal @user_1.id, ticket.reload.agent_id

    ticket_2 = create :ticket, organization: @organization, group: nil
    Desk::Automation::Actions::AssignAgentService.new(@round_robin, ticket_2).run_round_robin
    assert_equal @user_2.id, ticket_2.reload.agent_id

    ticket_3 = create :ticket, organization: @organization, group: nil
    Desk::Automation::Actions::AssignAgentService.new(@round_robin, ticket_3).run_round_robin
    assert_equal @user_3.id, ticket_3.reload.agent_id

    ticket_4 = create :ticket, organization: @organization, group: nil
    Desk::Automation::Actions::AssignAgentService.new(@round_robin, ticket_4).run_round_robin
    assert_equal @user_1.id, ticket_4.reload.agent_id
  end

  def test_assign_agent_load_balanced
    ticket_1 = create :ticket, organization: @organization, group: nil, agent_id: @user_1.id, status: "new"
    ticket_2 = create :ticket, organization: @organization, group: nil, agent_id: @user_2.id, status: "open"
    ticket_3 = create :ticket, organization: @organization, group: nil
    ticket_4 = create :ticket, organization: @organization, group: nil
    ticket_5 = create :ticket, organization: @organization, group: nil
    ticket_6 = create :ticket, organization: @organization, group: nil

    Desk::Automation::Actions::AssignAgentService.new(@load_balanced, ticket_3).run_load_balanced
    assert_equal @user_3.id, ticket_3.reload.agent_id

    ticket_4.update(agent_id: @user_1.id)
    ticket_5.update(agent_id: @user_2.id)

    Desk::Automation::Actions::AssignAgentService.new(@load_balanced, ticket_6).run_load_balanced
    assert_equal @user_3.id, ticket_6.reload.agent_id
  end

  def test_that_load_balanced_considers_only_new_and_open_tickets
    ticket_1 = create :ticket, organization: @organization, group: nil, agent_id: @user_1.id, status: "closed"
    ticket_2 = create :ticket, organization: @organization, group: nil, agent_id: @user_2.id, status: "resolved"
    ticket_3 = create :ticket, organization: @organization, group: nil
    ticket_4 = create :ticket, organization: @organization, group: nil
    ticket_5 = create :ticket, organization: @organization, group: nil
    ticket_6 = create :ticket, organization: @organization, group: nil

    Desk::Automation::Actions::AssignAgentService.new(@load_balanced, ticket_3).run_load_balanced
    assert_equal @user_1.id, ticket_3.reload.agent_id
  end

  def test_assign_agent_round_robin_for_a_ticket_with_group
    user_5 = create :user, organization: @organization,
      role: @agent_role

    group = create :group, organization: @organization
    create :group_member, group: group, user: @user_3
    create :group_member, group: group, user: user_5

    ticket = create :ticket, organization: @organization, group_id: group.id

    Desk::Automation::Actions::AssignAgentService.new(@round_robin, ticket).run_round_robin
    assert_equal @user_3.id, ticket.reload.agent_id
  end

  def test_assign_agent_load_balanced_for_a_ticket_with_group
    user_5 = create :user, organization: @organization,
      role: @agent_role

    group = create :group, organization: @organization
    create :group_member, group: group, user: @user_3
    create :group_member, group: group, user: user_5

    create :ticket, organization: @organization, agent_id: @user_3.id

    ticket = create :ticket, organization: @organization, group_id: group.id

    Desk::Automation::Actions::AssignAgentService.new(@load_balanced, ticket).run_load_balanced
    assert_equal user_5.id, ticket.reload.agent_id
  end

  def test_assign_agent_round_robin_when_group_is_empty
    group = create :group, organization: @organization
    create :group_member, group: group, user: @user_4

    ticket = create :ticket, organization: @organization, group_id: group.id

    Desk::Automation::Actions::AssignAgentService.new(@round_robin, ticket).run_round_robin
    assert_nil ticket.reload.agent_id
  end

  def test_assign_agent_load_balanced_when_group_is_empty
    group = create :group, organization: @organization
    create :group_member, group: group, user: @user_4

    create :ticket, organization: @organization, agent_id: @user_3.id

    ticket = create :ticket, organization: @organization, group_id: group.id

    Desk::Automation::Actions::AssignAgentService.new(@round_robin, ticket).run_load_balanced
    assert_nil ticket.reload.agent_id
  end

  def test_assign_agent_round_robin_for_a_ticket_with_multiple_groups
    user_5 = create :user, organization: @organization,
      role: @agent_role

    group_1 = create :group, organization: @organization
    create :group_member, group: group_1, user: @user_1
    create :group_member, group: group_1, user: @user_2

    group_2 = create :group, organization: @organization
    create :group_member, group: group_2, user: @user_3
    create :group_member, group: group_2, user: @user_4
    create :group_member, group: group_2, user: user_5

    ticket_1 = create :ticket, organization: @organization, group_id: group_1.id
    Desk::Automation::Actions::AssignAgentService.new(@round_robin, ticket_1).run_round_robin
    assert_equal @user_1.id, ticket_1.reload.agent_id

    ticket_2 = create :ticket, organization: @organization, group_id: group_2.id
    Desk::Automation::Actions::AssignAgentService.new(@round_robin, ticket_2).run_round_robin
    assert_equal @user_3.id, ticket_2.reload.agent_id

    ticket_3 = create :ticket, organization: @organization, group_id: group_1.id
    Desk::Automation::Actions::AssignAgentService.new(@round_robin, ticket_3).run_round_robin
    assert_equal @user_2.id, ticket_3.reload.agent_id

    ticket_4 = create :ticket, organization: @organization, group_id: group_2.id
    Desk::Automation::Actions::AssignAgentService.new(@round_robin, ticket_4).run_round_robin
    assert_equal user_5.id, ticket_4.reload.agent_id
  end

  def test_not_assign_deactivated_agent_tickets_in_round_robin
    group = create :group, organization: @organization

    create :group_member, group: group, user: @user_1
    create :group_member, group: group, user: @user_2
    create :group_member, group: group, user: @user_3

    ticket = create :ticket, organization: @organization, group_id: group.id

    available_agent_ids = Desk::Automation::Actions::AssignAgentService.new(@round_robin, ticket).available_agent_ids
    assert_equal available_agent_ids.count, group.group_members.count

    @user_1.deactivate!
    available_agent_ids = Desk::Automation::Actions::AssignAgentService.new(@round_robin, ticket).available_agent_ids
    assert_not available_agent_ids.include?(@user_1.id)

    @user_1.activate!
    available_agent_ids = Desk::Automation::Actions::AssignAgentService.new(@round_robin, ticket).available_agent_ids
    assert available_agent_ids.include?(@user_1.id)
  end

  def test_not_assign_deactivated_agent_tickets_in_load_balanced
    group = create :group, organization: @organization

    create :group_member, group: group, user: @user_1
    create :group_member, group: group, user: @user_2
    create :group_member, group: group, user: @user_3

    ticket = create :ticket, organization: @organization, group_id: group.id

    available_agent_ids = Desk::Automation::Actions::AssignAgentService.new(@load_balanced, ticket).available_agent_ids
    assert_equal available_agent_ids.count, group.group_members.count

    @user_1.deactivate!
    available_agent_ids = Desk::Automation::Actions::AssignAgentService.new(@load_balanced, ticket).available_agent_ids
    assert_not available_agent_ids.include?(@user_1.id)

    @user_1.activate!
    available_agent_ids = Desk::Automation::Actions::AssignAgentService.new(@load_balanced, ticket).available_agent_ids
    assert available_agent_ids.include?(@user_1.id)
  end
end
