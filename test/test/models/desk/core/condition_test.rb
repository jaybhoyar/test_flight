# frozen_string_literal: true

require "test_helper"

module Desk
  module Core
    class ConditionTest < ActiveSupport::TestCase
      def setup
        @organization = create :organization
        @rule = create :desk_core_rule

        @condition_1 = create :desk_core_condition, conditionable: @rule
      end

      def test_sequence_generation
        condition_2 = create :desk_core_condition, conditionable: @rule

        assert_equal 1, @condition_1.sequence
        assert_equal 2, condition_2.sequence
      end

      def test_valid_rule
        assert @condition_1.valid?
      end

      def test_invalid_rule
        @condition_1.join_type = ""
        @condition_1.verb = ""

        assert_not @condition_1.valid?
        assert_includes @condition_1.errors.messages[:join_type], " is not a valid join operation."
        assert_includes @condition_1.errors.messages[:verb], " is not a valid verb."
      end
    end
  end
end
