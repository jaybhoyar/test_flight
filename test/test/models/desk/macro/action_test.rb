# frozen_string_literal: true

require "test_helper"

module Desk
  module Macro
    class ActionTest < ActiveSupport::TestCase
      def test_that_action_is_valid
        action = build :desk_macro_action, name: "add_reply", body: "Test body"
        assert action.valid?
      end

      def test_that_action_is_executed
        action = create :desk_macro_action, name: "change_status", value: "Test"
        ticket = create :ticket, organization: action.rule.organization

        action.execute!(ticket)

        assert_equal "Test", ticket.reload.status
      end
    end
  end
end
