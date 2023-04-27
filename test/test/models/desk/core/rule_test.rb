# frozen_string_literal: true

require "test_helper"

module Desk
  module Core
    class RuleTest < ActiveSupport::TestCase
      def test_that_rule_is_valid
        rule = create :desk_core_rule
        assert rule.valid?
      end
    end
  end
end
