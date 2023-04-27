# frozen_string_literal: true

require "test_helper"

module Desk
  module Core
    class ActionTest < ActiveSupport::TestCase
      def test_that_action_is_invalid_without_name
        action = build :desk_core_action
        assert action.valid?
      end
    end
  end
end
