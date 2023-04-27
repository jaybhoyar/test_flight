# frozen_string_literal: true

require "test_helper"

module Desk
  module Automation
    class RuleTest < ActiveSupport::TestCase
      def setup
        @organization = create(:organization)
        @refund_ticket = create(:ticket, subject: "Please Refund my money!", organization: @organization)
        @urgent_ticket = create(
          :ticket, subject: "[Urgent] Cannot see any incoming tickets",
          organization: @organization)
        @combo_ticket = create(:ticket, subject: "Refund my money - Urgent", organization: @organization)
        @assigned_to_ooo_ticket = create(:ticket, organization: @organization)
      end

      def test_that_rule_is_valid
        rule = build :automation_rule
        assert rule.valid?
      end

      def test_rule_is_not_valid_without_name
        rule = build :automation_rule, name: nil
        assert_not rule.valid?
      end

      def test_that_rule_has_valid_display_order
        rule_1 = create :automation_rule, organization: @organization, name: "Rule 1"
        rule_2 = create :automation_rule, organization: @organization, name: "Rule 2"

        assert_equal 2, rule_2.display_order
      end

      test "matching_tickets - single condition" do
        rule = create(:automation_rule, organization: @organization)
        group = create :automation_condition_group, rule: rule
        condition_subject_contains_refund = create(:automation_condition_subject_contains_refund, conditionable: group)

        rule.reload
        assert_includes rule.matching_tickets, @refund_ticket
      end

      test "matching_tickets - C1 OR C2" do
        rule = create(:automation_rule, organization: @organization)
        group = create :automation_condition_group, :match_any, rule: rule

        c1 = create(:automation_condition_subject_contains_refund, conditionable: group, sequence: 1)
        c2 = create(:automation_condition_subject_contains_urgent, conditionable: group, sequence: 2)

        rule.reload

        assert_equal 3, rule.matching_tickets.count
        assert_includes rule.matching_tickets, @refund_ticket
        assert_includes rule.matching_tickets, @urgent_ticket
        assert_includes rule.matching_tickets, @combo_ticket
      end

      test "matching_tickets - C1 AND C2" do
        rule = create(:automation_rule, organization: @organization)
        group = create :automation_condition_group, rule: rule

        c1 = create(:automation_condition_subject_contains_refund, conditionable: group, sequence: 1)
        c2 = create(
          :automation_condition_subject_contains_urgent, conditionable: group, sequence: 2,
          join_type: "and_operator")

        rule.reload
        assert_equal 1, rule.matching_tickets.count
        assert_equal [@combo_ticket], rule.matching_tickets
      end

      def test_tickets_from_different_channel_dont_match_with_rule
        rule = create :automation_rule, organization: @organization
        group = create :automation_condition_group, rule: rule
        create :automation_condition, conditionable: group, field: "channel", verb: "is", value: "twitter"
        create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "refund"

        assert_equal 0, rule.matching_tickets.count
      end

      def test_tickets_from_same_channel_match_with_rule
        rule = create :automation_rule, organization: @organization
        group = create :automation_condition_group, rule: rule
        create :automation_condition, conditionable: group, field: "channel", verb: "is", value: "twitter"
        create :automation_condition, conditionable: group, field: "subject", verb: "contains", value: "refund"
        @refund_ticket.twitter!

        assert_equal 1, rule.matching_tickets.count
      end

      def matching_tickets_assigned_to_ooo_agents
        rule = create :automation_rule, organization: @organization
        group = create :automation_condition_group, rule: rule

        agent = create :agent, available_for_desk: false
        @assigned_to_ooo_ticket.update!(agent:)

        condition = create :automation_condition, conditionable: group, field: "agent.available_for_desk", verb: "is", value: "false"

        rule.reload
        assert_includes rule.matching_tickets, @assigned_to_ooo_ticket
      end

      # Test that_match?
      # 1. on_create
      # 2. time_based
      # 3. on_update
      #       1. updated
      #       2. trashed
      #       3. spammed
      #       4. priority_changed
      #       5. category_changed
      #       6. status_changed
      #       7. group_updated
      #       8. agent_updated
      #       9. note_added
      #       10. reply_added
      #       11. feedback_received

      def test_that_ticket_does_not_match_with_rule
        refund_rule = create :automation_rule,
          name: "Assign tag billing when subject contains refund",
          organization: @organization
        refund_group = create :automation_condition_group, rule: refund_rule
        create :automation_condition_subject_contains_refund, conditionable: refund_group

        assert_empty Desk::Automation::Rule.that_match(@urgent_ticket, "created")
      end

      def test_that_ticket_does_not_match_with_rule_with_other_execution_type
        refund_rule = create :automation_rule,
          name: "Assign tag billing when subject contains refund",
          organization: @organization
        refund_group = create :automation_condition_group, rule: refund_rule
        create :automation_condition_subject_contains_refund, conditionable: refund_group

        assert_empty Desk::Automation::Rule.that_match(@refund_ticket, "created")
      end

      def test_that_ticket_matches_with_rule
        refund_rule = create :automation_rule, :on_ticket_create,
          name: "Assign tag billing when subject contains refund",
          organization: @organization
        refund_group = create :automation_condition_group, rule: refund_rule
        create :automation_condition_subject_contains_refund, conditionable: refund_group

        assert_equal [refund_rule], Desk::Automation::Rule.that_match(@refund_ticket, "created")
      end

      def test_that_ticket_matches_to_rule_with_events
        event = build :automation_event, name: :updated

        refund_rule = create :automation_rule,
          name: "Assign tag billing when subject contains refund",
          organization: @organization,
          events: [event]
        refund_group = create :automation_condition_group, rule: refund_rule
        create :automation_condition_subject_contains_refund, conditionable: refund_group

        assert_equal [refund_rule], Desk::Automation::Rule.that_match(@refund_ticket, "updated")
      end

      def test_that_ticket_matches_to_rule_with_one_of_the_events
        events = []
        events << build(:automation_event, name: :priority_changed)
        events << build(:automation_event, name: :category_changed)
        events << build(:automation_event, name: :status_changed)

        refund_rule = create :automation_rule,
          name: "Assign tag billing when subject contains refund",
          organization: @organization,
          events: events
        refund_group = create :automation_condition_group, rule: refund_rule
        create :automation_condition_subject_contains_refund, conditionable: refund_group

        assert_equal [refund_rule], Desk::Automation::Rule.that_match(@refund_ticket, "status_changed")
      end

      def test_that_ticket_matches_to_rule_with_one_of_the_events_with_performers
        events = []
        events << build(:automation_event, name: :priority_changed)
        events << build(:automation_event, name: :category_changed)
        events << build(:automation_event, name: :status_changed)

        refund_rule = create :automation_rule, performer: :agent_or_requester,
          name: "Assign tag billing when subject contains refund",
          organization: @organization,
          events: events
        refund_group = create :automation_condition_group, rule: refund_rule
        create :automation_condition_subject_contains_refund, conditionable: refund_group

        assert_equal [refund_rule], Desk::Automation::Rule.that_match(@refund_ticket, "status_changed", "agent")
        assert_equal [refund_rule], Desk::Automation::Rule.that_match(@refund_ticket, "status_changed", "requester")
        assert_empty Desk::Automation::Rule.that_match(@refund_ticket, "status_changed", "any")
        assert_empty Desk::Automation::Rule.that_match(@refund_ticket, "status_changed", "system")
      end

      def test_that_ticket_does_not_match_to_rule_with_different_events
        event = build :automation_event, name: :trashed

        refund_rule = create :automation_rule,
          name: "Assign tag billing when subject contains refund",
          organization: @organization,
          events: [event]
        refund_group = create :automation_condition_group, rule: refund_rule
        create :automation_condition_subject_contains_refund, conditionable: refund_group

        assert_empty Desk::Automation::Rule.that_match(@refund_ticket, "updated")
      end

      def test_that_ticket_matches_with_multiple_rules
        refund_rule = create :automation_rule, :on_ticket_create,
          name: "Assign tag billing when subject contains refund",
          organization: @organization
        refund_group = create :automation_condition_group, rule: refund_rule
        create :automation_condition_subject_contains_refund, conditionable: refund_group

        urgent_rule = create :automation_rule, :on_ticket_create,
          name: "Assign tag billing when subject contains urgent",
          organization: @organization
        urgent_group = create :automation_condition_group, rule: urgent_rule
        create :automation_condition_subject_contains_urgent, conditionable: urgent_group

        matches = Desk::Automation::Rule.that_match(@combo_ticket, "created")

        assert_equal 2, matches.count
        assert_includes matches, refund_rule
        assert_includes matches, urgent_rule
      end

      def that_ticket_matches_on_rule_for_which_it_has_already_been_executed_less_than_100_times
        rule = create(:automation_rule, organization: @organization)
        group = create :automation_condition_group, rule: rule
        create :execution_log_entry, rule: rule, ticket: @refund_ticket

        assert_not_empty Desk::Automation::Rule.that_match(@refund_ticket, "created")
      end

      def test_that_time_based_rules_dont_match_with_a_ticket_after_execution
        rule = create :automation_rule, :time_based, organization: @organization
        group = create :automation_condition_group, rule: rule
        create :automation_condition_subject_contains_refund, conditionable: group

        assert_includes rule.reload.matching_tickets, @refund_ticket

        create :execution_log_entry, rule: rule, ticket: @refund_ticket

        assert_not_includes rule.reload.matching_tickets, @refund_ticket
      end

      def test_that_event_based_rules_match_with_a_ticket_even_after_execution
        rule = create :automation_rule, :on_ticket_create, organization: @organization
        group = create :automation_condition_group, rule: rule
        create :automation_condition_subject_contains_refund, conditionable: group

        assert_includes rule.reload.matching_tickets, @refund_ticket

        create :execution_log_entry, rule: rule, ticket: @refund_ticket

        assert_includes rule.reload.matching_tickets, @refund_ticket
      end

      def test_that_ticket_doesnt_match_on_rule_for_which_it_is_skipped
        refund_ticket_2 = create(:ticket, subject: "When can I expect my refund?", organization: @organization)
        rule = create(:automation_rule, organization: @organization)
        group = create :automation_condition_group, rule: rule

        assert_empty Desk::Automation::Rule.that_match(refund_ticket_2, "created", nil, [rule.id])
      end

      def test_that_comments_author_is_nil_when_a_rule_with_comments_is_deleted
        rule = create :automation_rule, organization: @organization
        create :comment, comment_type: :description, ticket: @refund_ticket, author: @refund_ticket.requester
        note = create :comment, comment_type: :note, ticket: @refund_ticket, author: rule

        rule.destroy!

        assert_nil note.reload.author_id
        assert_nil note.reload.author_type
      end

      def test_that_closed_tickets_are_not_matched
        rule = create :automation_rule, organization: @organization
        group = create :automation_condition_group, rule: rule
        create :automation_condition_subject_contains_refund, conditionable: group
        @refund_ticket.update!(status: ::Ticket::DEFAULT_STATUSES[:closed])

        assert_not rule.reload.match?(@refund_ticket)
      end
    end
  end
end
