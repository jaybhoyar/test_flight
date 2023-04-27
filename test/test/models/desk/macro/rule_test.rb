# frozen_string_literal: true

require "test_helper"

module Desk
  module Macro
    class RuleTest < ActiveSupport::TestCase
      def test_that_rule_is_valid
        rule = build :desk_macro_rule
        assert rule.valid?
      end

      def test_that_rule_is_invalid
        rule = build :desk_macro_rule, name: nil
        refute rule.valid?
      end
    end
  end
end
