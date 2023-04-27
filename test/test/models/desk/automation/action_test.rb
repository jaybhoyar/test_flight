# frozen_string_literal: true

require "test_helper"

module Desk
  module Automation
    class ActionTest < ActiveSupport::TestCase
      def setup
        User.current = create(:user)
      end

      def test_validation_for_set_tags
        tag_1 = create :ticket_tag
        tag_2 = create :ticket_tag

        action = build :automation_action, name: "set_tags", tag_ids: [tag_1.id, tag_2.id]
        assert action.valid?

        action_2 = build :automation_action, name: "set_tags", tag_ids: []
        assert_not action_2.valid?
      end

      def test_validation_for_add_tags
        tag_1 = create :ticket_tag
        tag_2 = create :ticket_tag

        action = build :automation_action, name: "add_tags", tag_ids: [tag_1.id, tag_2.id]
        assert action.valid?

        action_2 = build :automation_action, name: "add_tags", tag_ids: []
        assert_not action_2.valid?
      end

      def test_validation_for_remove_tags
        tag_1 = create :ticket_tag
        tag_2 = create :ticket_tag

        action = build :automation_action, name: "remove_tags", tag_ids: [tag_1.id, tag_2.id]
        assert action.valid?

        action_2 = build :automation_action, name: "remove_tags", tag_ids: []
        assert_not action_2.valid?
      end

      def test_validation_for_assign_group
        group = create :group
        action = build :automation_action, name: "assign_group", actionable: group
        assert action.valid?

        action_2 = build :automation_action, name: "assign_group", actionable: nil
        assert_not action_2.valid?
      end

      def test_validation_without_agent_id
        action = build :automation_action, name: "assign_agent", actionable: nil
        assert_not action.valid?

        agent = create :user
        action_2 = build :automation_action, name: "assign_agent", actionable: agent

        assert action_2.valid?
      end

      def test_validation_without_status
        action = build :automation_action, name: "change_ticket_status", status: nil
        assert_not action.valid?

        action_2 = build :automation_action,
          name: "change_ticket_status",
          status: "resolved"

        assert action_2.valid?
      end

      def test_validation_without_subject_body
        action = build :automation_action, name: "email_to_requester", subject: nil, body: nil
        assert_not action.valid?

        action_2 = build :automation_action,
          name: "email_to_requester",
          subject: "Our team is already working on the issue.",
          body: "We will fix this ASAP."

        assert action_2.valid?
      end

      def test_validation_without_body
        action = build :automation_action, name: "add_note", body: nil
        assert_not action.valid?

        action_2 = build :automation_action, name: "add_note", body: "We will fix this ASAP."
        assert action_2.valid?
      end

      def test_validation_for_email_to
        action = build :automation_action, name: "email_to", value: nil, subject: nil, body: nil
        assert_not action.valid?

        action_2 = build :automation_action, name: "email_to",
          value: "payments@example.com",
          subject: "We have received a payment failure",
          body: "We will fix this ASAP."
        assert action_2.valid?
      end

      def test_validation_for_add_task_list
        refund_task_list = create :desk_task_list
        action = build :automation_action, name: "add_task_list", actionable: refund_task_list
        assert action.valid?

        action_2 = build :automation_action, name: "add_task_list", actionable: nil
        assert_not action_2.valid?
      end

      def test_that_action_is_invalid_with_wrong_params
        assert_raise(ArgumentError) { ::Desk::Automation::Action.new(name: "assign_owner").valid? }
      end

      def test_that_assign_agent_action_works
        agent = create(:user)
        ticket = create(:ticket)

        action = create :automation_action, name: "assign_agent", actionable: agent
        action.execute!(ticket)

        assert_equal ticket.agent, action.actionable
      end

      def test_that_remove_assigned_agent_works
        agent = create :user, available_for_desk: false
        ticket = create(:ticket)

        action = create :automation_action, name: "remove_assigned_agent"
        action.execute!(ticket)

        assert_nil ticket.agent
      end
    end
  end
end
