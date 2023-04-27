# frozen_string_literal: true

require "test_helper"

module Desk
  module CustomerSatisfaction
    class ScaleChoiceTest < ActiveSupport::TestCase
      def test_valid_customer_satisfaction_scale_choice
        scale_choice = create(:default_question_scale_choice_1)

        assert scale_choice.valid?
      end

      def test_invalid_customer_satisfaction_scale_choice
        invalid_scale_choice = ::Desk::CustomerSatisfaction::ScaleChoice.new

        assert_not invalid_scale_choice.valid?
        assert_includes invalid_scale_choice.errors.full_messages, "Text can't be blank"
      end
    end
  end
end
