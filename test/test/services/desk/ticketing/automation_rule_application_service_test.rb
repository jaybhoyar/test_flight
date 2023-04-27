# frozen_string_literal: true

require "test_helper"

module Desk::Ticketing
  class AutomationRuleApplicationServiceTest < ActiveSupport::TestCase
    def setup
      @organization = create :organization
      @organization_role = create :organization_role_agent, organization: @organization
      @ethan = create :user, role: @organization_role, organization: @organization

      @tag = create :ticket_tag, name: "billing", organization: @organization

      @ticket = create :ticket,
        subject: "Please refund me urgently. promotional message!",
        organization: @organization,
        requester: create(:user, organization: @organization),
        agent: create(:user, organization: @organization),
        priority: 2,
        category: "None"

      @refund_rule = create :automation_rule, :on_ticket_create,
        name: "Assign tag billing when subject contains refund",
        organization: @organization
      @refund_group = create :automation_condition_group, rule: @refund_rule
      create :automation_condition, field: "subject", verb: "contains", value: "refund", conditionable: @refund_group
      create :automation_action, rule: @refund_rule, name: "set_tags", tag_ids: [@tag.id], status: nil

      @status_rule = create :automation_rule, :on_ticket_create,
        name: "Change status to spam when subject contains promo",
        organization: @organization
      @status_group = create :automation_condition_group, rule: @status_rule
      create :automation_condition, conditionable: @status_group, field: "subject", verb: "contains", value: "promo"
      create :automation_action, rule: @status_rule, name: "change_ticket_status", status: "spam"

      @agent_rule = create :automation_rule, :on_ticket_create,
        name: "Assign ticket to Ethan when subject contains urgent",
        organization: @organization
      @agent_group = create :automation_condition_group, rule: @agent_rule
      create :automation_condition, conditionable: @agent_group, field: "subject", verb: "contains", value: "urgent"
      create :automation_action, rule: @agent_rule, name: "assign_agent", actionable: @ethan

      refund_rule_2 = create :automation_rule, :on_reply_added,
        name: "Assign tag billing when subject contains refund on create or reply",
        organization: @organization
      group = create :automation_condition_group, rule: refund_rule_2
      create :automation_condition, field: "subject", verb: "contains", value: "refund", conditionable: group
      create :automation_action, rule: refund_rule_2, name: "set_tags", tag_ids: [@tag.id], status: nil
      User.current = @ethan
    end

    def test_that_on_create_rules_are_applied_then_dependent_event_rules_performed_by_any_or_system_are_applied
      assert_empty @ticket.tags
      assert_not_equal @ethan.id, @ticket.agent_id

      # This should match
      agent_rule_2 = create :automation_rule, :on_agent_updated,
        name: "When ticket is assigned to Ethan, mark it as urgent",
        organization: @organization

      group_1 = create :automation_condition_group, rule: agent_rule_2
      create :automation_condition, conditionable: group_1, field: "agent_id", verb: "is", value: @ethan.id
      create :automation_action, rule: agent_rule_2, name: "change_ticket_priority", value: "urgent"

      # This should NOT match
      agent_rule_3 = create :automation_rule, :on_agent_updated,
        performer: :agent,
        name: "When ticket is assigned to Ethan, send email to ethan",
        organization: @organization

      group_2 = create :automation_condition_group, rule: agent_rule_3
      create :automation_condition, conditionable: group_2, field: "agent_id", verb: "is", value: @ethan.id
      create :automation_action, rule: agent_rule_3, name: "email_to_assigned_agent", subject: "test", body: "test"

      # This should match
      agent_rule_4 = create :automation_rule, :on_agent_updated,
        performer: :system,
        name: "When ticket is assigned to Ethan, send email to customer",
        organization: @organization

      group_3 = create :automation_condition_group, rule: agent_rule_4
      create :automation_condition, conditionable: group_3, field: "agent_id", verb: "is", value: @ethan.id
      create :automation_action, rule: agent_rule_4, name: "email_to_requester", subject: "test", body: "test"

      assert_difference "Desk::Automation::ExecutionLogEntry.count", 5 do
        Desk::Ticketing::AutomationRuleApplicationService.new(@ticket, "created").process
      end

      @ticket.reload

      assert_equal 1, @ticket.tags.count
      assert_equal @tag.name, @ticket.tags.first.name
      assert_equal "spam", @ticket.status
      assert_equal @ethan.id, @ticket.agent_id
      assert_equal "urgent", @ticket.priority
    end

    def test_that_rules_are_applied_for_ticket_on_reply
      assert_empty @ticket.tags
      assert_not_equal @ethan.id, @ticket.agent_id

      assert_difference "Desk::Automation::ExecutionLogEntry.count", 1 do
        Desk::Ticketing::AutomationRuleApplicationService.new(@ticket, "reply_added").process
      end

      @ticket.reload

      assert_equal 1, @ticket.tags.count
      assert_equal @tag.name, @ticket.tags.first.name
    end

    def test_that_rules_are_applied_for_ticket_on_update
      refund_rule_3 = create :automation_rule, :on_ticket_update,
        name: "Assign tag billing when subject contains refund on create or update",
        organization: @ticket.organization

      group = create :automation_condition_group, rule: refund_rule_3
      create :automation_condition_subject_contains_refund, conditionable: group
      create :automation_action, rule: refund_rule_3, name: "set_tags", tag_ids: [@tag.id], status: nil

      assert_empty @ticket.tags
      assert_not_equal @ethan.id, @ticket.agent_id

      assert_difference "Desk::Automation::ExecutionLogEntry.count", 1 do
        Desk::Ticketing::AutomationRuleApplicationService.new(@ticket, "updated").process
      end

      @ticket.reload

      assert_equal 1, @ticket.tags.count
      assert_equal @tag.name, @ticket.tags.first.name
    end

    def test_that_rules_are_applied_for_ticket_on_update_by_performer
      refund_rule_3 = create :automation_rule, :on_ticket_update,
        performer: :agent,
        name: "Assign tag billing when subject contains refund on create or update",
        organization: @ticket.organization
      group = create :automation_condition_group, rule: refund_rule_3
      create :automation_condition_subject_contains_refund, conditionable: group
      create :automation_action, rule: refund_rule_3, name: "set_tags", tag_ids: [@tag.id], status: nil

      assert_empty @ticket.tags
      assert_not_equal @ethan.id, @ticket.agent_id

      assert_difference "Desk::Automation::ExecutionLogEntry.count", 1 do
        Desk::Ticketing::AutomationRuleApplicationService.new(@ticket, "updated", "agent").process
      end

      @ticket.reload

      assert_equal 1, @ticket.tags.count
      assert_equal @tag.name, @ticket.tags.first.name
    end

    def test_that_rules_are_not_applied_for_ticket_on_update_by_different_performer
      refund_rule_3 = create :automation_rule, :on_ticket_update,
        performer: :agent,
        name: "Assign tag billing when subject contains refund on create or update",
        organization: @ticket.organization
      group = create :automation_condition_group, rule: refund_rule_3
      create :automation_condition_subject_contains_refund, conditionable: group
      create :automation_action, rule: refund_rule_3, name: "set_tags", tag_ids: [@tag.id], status: nil

      assert_empty @ticket.tags
      assert_not_equal @ethan.id, @ticket.agent_id

      assert_no_difference "Desk::Automation::ExecutionLogEntry.count" do
        Desk::Ticketing::AutomationRuleApplicationService.new(@ticket, "updated", "requester").process
      end

      @ticket.reload
      assert_empty @ticket.tags
    end

    def test_that_rules_are_not_applied_for_ticket_from_different_channel
      @ticket.twitter!

      create :automation_condition, conditionable: @refund_group, field: "channel", verb: "is", value: "ui"
      create :automation_condition, conditionable: @status_group, field: "channel", verb: "is", value: "ui"
      create :automation_condition, conditionable: @agent_group, field: "channel", verb: "is", value: "ui"

      assert_difference "Desk::Automation::ExecutionLogEntry.count", 0 do
        Desk::Ticketing::AutomationRuleApplicationService.new(@ticket, "created").process
      end

      @ticket.reload

      assert_equal 0, @ticket.tags.count
      assert_equal "open", @ticket.status
    end

    def test_that_rules_are_applied_for_ticket_from_same_channel
      @ticket.twitter!

      create :automation_condition, conditionable: @refund_group, field: "channel", verb: "is", value: "twitter"
      create :automation_condition, conditionable: @agent_group, field: "channel", verb: "is", value: "ui"

      assert_difference "Desk::Automation::ExecutionLogEntry.count", 2 do
        Desk::Ticketing::AutomationRuleApplicationService.new(@ticket, "created").process
      end

      @ticket.reload

      assert_equal 1, @ticket.tags.count
      assert_equal @tag.name, @ticket.tags.first.name
      assert_equal "spam", @ticket.status
    end

    def test_that_rules_are_applied_in_correct_order
      rule_1 = create :automation_rule, :on_ticket_create, name: "Rule 1", organization: @organization, display_order: 4
      group_1 = create :automation_condition_group, rule: rule_1
      create :automation_condition, conditionable: group_1, field: "status", verb: "is", value: "waiting_on_customer"
      create :automation_action, rule: rule_1, name: "set_tags", tag_ids: [@tag.id]

      rule_2 = create :automation_rule, :on_ticket_create, name: "Rule 2", organization: @organization, display_order: 3
      group_2 = create :automation_condition_group, rule: rule_2
      create :automation_condition, conditionable: group_2, field: "subject", verb: "contains", value: "ticket"
      create :automation_action, rule: rule_2, name: "change_ticket_status", status: "on_hold"

      @ticket.update(subject: "Ticket 1", status: "waiting_on_customer")

      Sidekiq::Testing.inline! do
        assert_difference "Desk::Automation::ExecutionLogEntry.count", 2 do
          Desk::Ticketing::AutomationRuleApplicationService.new(@ticket.reload, "created").process
        end
      end

      assert_equal "on_hold", @ticket.status
      assert_includes @ticket.tags, @tag
    end

    def test_assign_to_first_responder_rule_application
      user = create :user, role: @organization_role, organization: @organization
      user_2 = create :user, organization: @organization, role: @organization_role

      ticket = create :ticket, requester: user, organization: @organization
      create :comment, ticket: ticket, author: user, created_at: Time.current - 5.minutes
      create :comment, ticket: ticket, author: user_2, created_at: Time.current

      rule = create :automation_rule, :on_ticket_create, organization: @organization
      action = create :automation_action, name: "assign_to_first_responder", rule: rule

      assert_difference "Desk::Automation::ExecutionLogEntry.count", 1 do
        Desk::Ticketing::AutomationRuleApplicationService.new(ticket.reload, "created").process
      end

      assert_equal user.id, ticket.reload.agent_id
    end

    def test_log_is_not_created_when_action_is_not_executed_for_a_ticket
      user = create :user, role: @organization_role, organization: @organization
      user_2 = create :user, organization: @organization, role: @organization_role

      ticket = create :ticket, requester: user, organization: @organization
      rule = create :automation_rule, :on_reply_added, organization: @organization
      action = create :automation_action, name: "assign_to_first_responder", rule: rule

      assert_no_difference "Desk::Automation::ExecutionLogEntry.count" do
        Desk::Ticketing::AutomationRuleApplicationService.new(ticket.reload, "reply_added").process
      end

      assert_nil ticket.reload.agent_id

      create :comment, ticket: ticket, author: user, created_at: Time.current - 5.minutes
      create :comment, ticket: ticket, author: user_2, created_at: Time.current

      assert_difference "Desk::Automation::ExecutionLogEntry.count", 1 do
        Desk::Ticketing::AutomationRuleApplicationService.new(ticket.reload, "reply_added").process
      end

      assert_equal user.id, ticket.reload.agent_id
    end

    def test_that_log_is_not_created_when_agent_is_not_assigned_and_created_when_agent_is_assigned_to_ticket
      ticket = create :ticket, organization: @organization
      rule = create :automation_rule, :on_ticket_update,
        name: "Notify assigned agent",
        organization: @organization,
        display_order: 4
      group = create :automation_condition_group, rule: rule
      create :automation_condition, conditionable: group, field: "agent_id", verb: "is_not", value: "Unassigned"
      create :automation_action,
        rule: rule,
        name: "email_to_assigned_agent",
        subject: "A ticket has been assigned to you.",
        body: "Hi {{ticket.agent.name}},\n\nA ticket has been assigned to you.\nClick on following url to go to the ticket.\n\n{{ticket.url}}"

      assert_no_difference "Desk::Automation::ExecutionLogEntry.count" do
        Desk::Ticketing::AutomationRuleApplicationService.new(ticket, "updated").process
      end

      ticket.assign_agent(@ethan.id)

      assert_difference "Desk::Automation::ExecutionLogEntry.count", 1 do
        Desk::Ticketing::AutomationRuleApplicationService.new(ticket.reload, "updated").process
      end
    end
  end
end
