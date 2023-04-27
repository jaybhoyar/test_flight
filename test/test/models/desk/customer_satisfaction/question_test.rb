# frozen_string_literal: true

require "test_helper"

module Desk
  module CustomerSatisfaction
    class QuestionTest < ActiveSupport::TestCase
      def test_valid_customer_satisfaction_question
        question = create(:default_question)

        assert question.valid?
      end

      def test_invalid_customer_satisfaction_question
        invalid_question = ::Desk::CustomerSatisfaction::Question.new

        assert_not invalid_question.valid?
        assert_includes invalid_question.errors.full_messages, "Text can't be blank"
        assert_includes invalid_question.errors.full_messages, "Point scale can't be blank"
      end

      def test_invalid_customer_satisfaction_question_point_scale
        invalid_question = ::Desk::CustomerSatisfaction::Question.new(point_scale: 10)

        assert_not invalid_question.valid?
        assert_includes invalid_question.errors.full_messages, "Point scale is not included in the list"
      end
    end
  end
end
