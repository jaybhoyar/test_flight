# frozen_string_literal: true

require "test_helper"

module Desk
  module Automation
    class ConditionTest < ActiveSupport::TestCase
      def setup
        @organization = create :organization
        @rule = create(:automation_rule)
        @ticket = create(:ticket, organization: @rule.organization)

        @condition_group = create :automation_condition_group, rule: @rule
        @condition_subject_contains_refund = create(
          :automation_condition_subject_contains_refund,
          conditionable: @condition_group)
        @condition_subject_equals_refund = create(
          :automation_condition_subject_equals_refund,
          conditionable: @condition_group)

        @refund_ticket = create(:ticket, subject: "Please Refund my money!", organization: @rule.organization)
        @refund_ticket2 = create(:ticket, subject: "Refund", organization: @rule.organization)

        @urgent_ticket = create(
          :ticket, subject: "[Urgent] Cannot see any incoming tickets",
          organization: @rule.organization)
      end

      def test_that_value_is_not_required_when_verb_is_any_time
        condition = build :automation_condition, value: nil, verb: "any_time"
        assert condition.valid?
      end

      def test_that_value_is_not_required_when_field_is_agent_id
        condition = build :automation_condition, value: nil, field: "agent_id"
        assert condition.valid?
      end

      def test_that_value_is_not_required_when_field_is_group_id
        condition = build :automation_condition, value: nil, field: "group_id"
        assert condition.valid?
      end

      test "matching_ticket? - 'subject contains'" do
        @ticket.update(subject: "Please Refund my money")
        assert @condition_subject_contains_refund.match_ticket?(@ticket)
      end

      test "matching_ticket? - 'subject equals'" do
        @ticket.update(subject: "Refund")
        assert @condition_subject_equals_refund.match_ticket?(@ticket)
      end

      test "matching_ticket? (case insensitive match)" do
        @ticket.update(subject: "Please refund my money")
        assert @condition_subject_contains_refund.match_ticket?(@ticket)
      end

      test "matching_ticket? - not matching" do
        @ticket.update(subject: "Happy Christmas!")
        assert_not @condition_subject_contains_refund.match_ticket?(@ticket)
      end

      test "matching_tickets - 'subject contains'" do
        assert_includes @condition_subject_contains_refund.matching_tickets, @refund_ticket
      end

      test "matching_tickets - 'subject equals'" do
        tickets = @condition_subject_equals_refund.matching_tickets
        assert_includes tickets, @refund_ticket2
      end

      test "matching_tickets - 'subject is not'" do
        is_not_condition = create(:automation_condition_subject_is_not_refund, conditionable: @condition_group)
        assert_equal 3, is_not_condition.matching_tickets.count
        assert_not_includes is_not_condition.matching_tickets, @refund_ticket2
      end

      test "matching_ticket? - subject not equal" do
        is_not_condition = create(:automation_condition_subject_is_not_refund, conditionable: @condition_group)
        assert is_not_condition.match_ticket?(@ticket)
        assert_not is_not_condition.match_ticket?(@refund_ticket2)
      end

      test "matching_tickets - 'subject does_not_contain'" do
        does_not_contain_condition = create(
          :automation_condition_subject_does_not_contain_refund,
          conditionable: @condition_group)
        assert_equal 2, does_not_contain_condition.matching_tickets.count
        assert_includes does_not_contain_condition.matching_tickets, @urgent_ticket
        assert_not_includes does_not_contain_condition.matching_tickets, @refund_ticket2
      end

      test "matching_ticket? - subject does_not_contain" do
        does_not_contain_condition = create(
          :automation_condition_subject_is_not_refund,
          conditionable: @condition_group)
        assert does_not_contain_condition.match_ticket?(@ticket)
        assert does_not_contain_condition.match_ticket?(@urgent_ticket)
        assert_not does_not_contain_condition.match_ticket?(@refund_ticket2)
      end

      test "matching_tickets - email equals" do
        email = "aditya.varma@author.com"
        rule = create :automation_rule, name: "When email is #{email} assign billing tag to ticket",
          organization: @rule.organization
        group = create :automation_condition_group, rule: rule
        condition = create :automation_condition, conditionable: group, field: "requester.email", verb: "is",
          value: email

        user = create :user, email: email, organization: @organization
        ticket = create :ticket, requester: user, organization: @rule.organization

        assert_includes condition.matching_tickets, ticket
      end

      test "matching_tickets - email not equals" do
        email = "aditya.varma@author.com"
        rule = create :automation_rule, name: "When email is not #{email} assign billing tag to ticket",
          organization: @rule.organization
        group = create :automation_condition_group, rule: rule
        condition = create :automation_condition, conditionable: group, field: "requester.email", verb: "is_not", value: email + ".not"

        user = create :user, email: email, organization: @organization
        ticket = create :ticket, requester: user, organization: @rule.organization

        assert_includes condition.matching_tickets, ticket
      end

      test "matching_tickets - email contains" do
        email = "aditya.varma@author.com"
        rule = create :automation_rule, name: "When email contains #{email} assign billing tag to ticket",
          organization: @rule.organization
        group = create :automation_condition_group, rule: rule
        condition = create :automation_condition, conditionable: group, field: "requester.email", verb: "contains", value: "aditya"

        user = create :user, email: email, organization: @organization
        ticket = create :ticket, requester: user, organization: @rule.organization

        assert_includes condition.matching_tickets, ticket
      end

      test "matching_tickets - email does not contain" do
        email = "aditya.varma@author.com"
        rule = create :automation_rule, name: "When email does not contain #{email} assign billing tag to ticket",
          organization: @rule.organization
        group = create :automation_condition_group, rule: rule
        condition = create :automation_condition, conditionable: group, field: "requester.email", verb: "does_not_contain", value: "rohit"

        user = create :user, email: email, organization: @organization
        ticket = create :ticket, requester: user, organization: @rule.organization

        assert_includes condition.matching_tickets, ticket
      end

      test "matching_ticket? - email equals" do
        email = "aditya.varma@author.com"
        rule = create :automation_rule, name: "When email is #{email} assign billing tag to ticket"
        group = create :automation_condition_group, rule: rule
        condition = create :automation_condition, conditionable: group, field: "requester.email", verb: "is",
          value: email

        user = create :user, email: email, organization: @organization
        ticket = create :ticket, requester: user

        assert condition.match_ticket?(ticket)
      end

      test "matching_ticket? - email not equals" do
        email = "aditya.varma@author.com"
        rule = create :automation_rule, name: "When email is #{email} assign billing tag to ticket"
        group = create :automation_condition_group, rule: rule
        condition = create :automation_condition, conditionable: group, field: "requester.email", verb: "is_not", value: email + ".not"

        user = create :user, email: email, organization: @organization
        ticket = create :ticket, requester: user

        assert condition.match_ticket?(ticket)
      end

      test "matching_ticket? - email contains" do
        email = "aditya.varma@author.com"
        rule = create :automation_rule, name: "When email is #{email} assign billing tag to ticket"
        group = create :automation_condition_group, rule: rule
        condition = create :automation_condition, conditionable: group, field: "requester.email", verb: "contains", value: "aditya"

        user = create :user, email: email, organization: @organization
        ticket = create :ticket, requester: user

        assert condition.match_ticket?(ticket)
      end

      test "matching_ticket? - email does_not_contain" do
        email = "aditya.varma@author.com"
        rule = create :automation_rule, name: "When email is #{email} assign billing tag to ticket"
        group = create :automation_condition_group, rule: rule
        condition = create :automation_condition, conditionable: group, field: "requester.email", verb: "does_not_contain", value: "rohit"

        user = create :user, email: email, organization: @organization
        ticket = create :ticket, requester: user

        assert condition.match_ticket?(ticket)
      end

      def test_match_ticket_for_created_at_column
        rule = create :automation_rule, organization: @rule.organization, name: "Handle tickets turing weekends"
        business_hour = create :business_hour, :weekend, organization: @rule.organization
        last_saturday = Time.current.beginning_of_week.advance(days: -2, hours: 10)

        @urgent_ticket.update(created_at: last_saturday)
        @refund_ticket2.update(created_at: last_saturday - 5.hours)

        group = create :automation_condition_group, rule: rule
        condition = create :automation_condition,
          conditionable: group,
          field: "created_at",
          verb: "during",
          value: business_hour.id

        assert condition.match_ticket?(@urgent_ticket)
        assert_not condition.match_ticket?(@refund_ticket2)
      end
    end
  end
end
