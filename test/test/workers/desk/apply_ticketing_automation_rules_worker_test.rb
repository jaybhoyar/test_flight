# frozen_string_literal: true

require "test_helper"
module Desk
  class ApplyTicketingAutomationRulesWorkerTest < ActiveSupport::TestCase
    require "sidekiq/testing"

    def setup
      Sidekiq::Testing.inline!

      ethan = create(:user)
      @organization = ethan.organization
      @tag = create :ticket_tag, name: "billing", organization: @organization
      @ticket = create :ticket, subject: "Please refund me urgently. promotional message!",
        organization: @organization,
        requester: create(:user),
        agent: ethan,
        priority: 2,
        category: "None"
    end

    def test_that_rules_are_applied_on_create
      refund_rule = create :automation_rule, :on_ticket_create,
        name: "Assign tag billing when subject contains refund",
        organization: @organization
      create :automation_condition_subject_contains_refund, conditionable: refund_rule
      create :automation_action, rule: refund_rule, name: "set_tags", tag_ids: [@tag.id], status: nil

      assert_empty @ticket.tags

      assert_difference "::Desk::Automation::ExecutionLogEntry.count" do
        ApplyTicketingAutomationRulesWorker.new.perform(@ticket.id, "created")
      end

      @ticket.reload
      assert_equal 1, @ticket.tags.count
      assert_equal @tag.name, @ticket.tags.first.name
    end

    def test_that_rules_are_not_applied_for_non_matching_events
      refund_rule = create :automation_rule, :on_ticket_update,
        name: "Assign tag billing when subject contains refund",
        organization: @organization
      create :automation_condition_subject_contains_refund, conditionable: refund_rule
      create :automation_action, rule: refund_rule, name: "set_tags", tag_ids: [@tag.id], status: nil

      assert_no_difference "::Desk::Automation::ExecutionLogEntry.count" do
        ApplyTicketingAutomationRulesWorker.new.perform(@ticket.id, "created")
      end

      assert_equal 0, @ticket.reload.tags.count
    end

    def test_that_rules_are_applied_with_matching_events
      refund_rule = create :automation_rule, :on_reply_added,
        name: "Assign tag billing when subject contains refund on reply",
        organization: @organization
      create :automation_condition_subject_contains_refund, conditionable: refund_rule
      create :automation_action, rule: refund_rule, name: "set_tags", tag_ids: [@tag.id], status: nil

      refund_rule_2 = create :automation_rule, :on_ticket_create,
        name: "Assign tag billing when subject contains refund on update",
        organization: @organization
      create :automation_condition_subject_contains_refund, conditionable: refund_rule_2
      create :automation_action, rule: refund_rule_2, name: "set_tags", tag_ids: [@tag.id], status: nil

      assert_empty @ticket.tags

      assert_difference "::Desk::Automation::ExecutionLogEntry.count" do
        ApplyTicketingAutomationRulesWorker.new.perform(@ticket.id, "reply_added")
      end

      @ticket.reload
      assert_equal 1, @ticket.tags.count
      assert_equal @tag.name, @ticket.tags.first.name
    end

    def test_that_rules_are_applied_on_update
      refund_rule = create :automation_rule, :on_ticket_update,
        name: "Assign tag billing when subject contains refund",
        organization: @organization
      create :automation_condition_subject_contains_refund, conditionable: refund_rule
      create :automation_action, rule: refund_rule, name: "set_tags", tag_ids: [@tag.id], status: nil

      assert_empty @ticket.tags

      assert_difference "::Desk::Automation::ExecutionLogEntry.count" do
        ApplyTicketingAutomationRulesWorker.new.perform(@ticket.id, "updated")
      end

      @ticket.reload
      assert_equal 1, @ticket.tags.count
      assert_equal @tag.name, @ticket.tags.first.name
    end

    def test_that_dependent_rules_are_applied
      ticket = create :ticket, subject: "Please refund me urgently. promotional message!",
        organization: @organization,
        requester: create(:user),
        category: "None"

      ethan = create :user, organization: @organization, first_name: "Ethan", last_name: "Hunt"

      rule_1 = create :automation_rule, :on_ticket_create,
        name: "Assign ticket to Ethan Hunt",
        organization: @organization

      condition_group_1 = create :automation_condition_group, :match_all, rule: rule_1
      create :automation_condition, conditionable: condition_group_1, field: "channel", verb: "is", value: "UI"
      create :automation_action, rule: rule_1, name: "assign_agent", actionable: ethan, status: nil

      # Dependent on rule_1
      rule_2 = create :automation_rule, :on_ticket_update,
        name: "Mark ETHAN's tickets as High priority",
        organization: @organization
      condition_group_2 = create :automation_condition_group, :match_all, rule: rule_2
      create :automation_condition, conditionable: condition_group_2, field: "agent_id", verb: "is", value: ethan.id
      create :automation_action, rule: rule_2, name: "change_ticket_priority", value: "high", status: nil

      # Dependent on rule_2
      rule_3 = create :automation_rule, :on_ticket_update,
        name: "Add tag to high priority tickets",
        organization: @organization
      condition_group_3 = create :automation_condition_group, :match_all, rule: rule_3
      create :automation_condition, conditionable: condition_group_3, field: "priority", verb: "is", value: "2"
      create :automation_action, rule: rule_3, name: "set_tags", tag_ids: [@tag.id], status: nil

      assert_nil ticket.agent_id
      assert_equal "low", ticket.priority

      assert_difference "::Desk::Automation::ExecutionLogEntry.count", 3 do
        ApplyTicketingAutomationRulesWorker.new.perform(ticket.id, "created")
      end

      ticket.reload
      assert_equal ethan.id, ticket.agent.id
      assert_equal "high", ticket.priority
      assert_equal @tag.name, ticket.tags.first.name
    end

    def test_that_deep_dependent_rules_are_applied
      ticket = create :ticket, subject: "Please refund me urgently. promotional message!",
        organization: @organization,
        requester: create(:user),
        category: "None"

      ethan = create :user, organization: @organization, first_name: "Ethan", last_name: "Hunt"

      rule_1 = create :automation_rule, :on_ticket_create,
        name: "Assign ticket to Ethan Hunt",
        organization: @organization

      condition_group_1 = create :automation_condition_group, :match_all, rule: rule_1
      create :automation_condition, conditionable: condition_group_1, field: "channel", verb: "is", value: "UI"
      create :automation_action, rule: rule_1, name: "assign_agent", actionable: ethan, status: nil

      # Dependent on rule_1
      rule_2 = create :automation_rule, :on_ticket_update,
        name: "Mark ETHAN's tickets as High priority",
        organization: @organization
      condition_group_2 = create :automation_condition_group, :match_all, rule: rule_2
      create :automation_condition, conditionable: condition_group_2, field: "agent_id", verb: "is", value: ethan.id
      create :automation_action, rule: rule_2, name: "add_note", body: "This is a note", status: nil

      # Dependent on rule_2
      rule_3 = create :automation_rule, :on_note_added,
        name: "Add tag to high priority tickets",
        organization: @organization
      condition_group_3 = create :automation_condition_group, :match_all, rule: rule_3
      create :automation_condition, conditionable: condition_group_3, field: "agent_id", verb: "is", value: ethan.id
      create :automation_action, rule: rule_3, name: "set_tags", tag_ids: [@tag.id], status: nil

      # This shall not pass as rule 2 emmits on_note_added and not on_reply_added event
      rule_3 = create :automation_rule, :on_reply_added,
        name: "Add more tags to high priority tickets",
        organization: @organization
      condition_group_3 = create :automation_condition_group, :match_all, rule: rule_3
      create :automation_condition, conditionable: condition_group_3, field: "agent_id", verb: "is", value: ethan.id
      create :automation_action, rule: rule_3, name: "set_tags", tag_ids: [@tag.id], status: nil

      assert_nil ticket.agent_id
      assert_equal "low", ticket.priority

      assert_difference "::Desk::Automation::ExecutionLogEntry.count", 3 do
        ApplyTicketingAutomationRulesWorker.new.perform(ticket.id, "created")
      end

      ticket.reload
      assert_equal ethan.id, ticket.agent.id
      assert_equal @tag.name, ticket.tags.first.name
    end
  end
end
