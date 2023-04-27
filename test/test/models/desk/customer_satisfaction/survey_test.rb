# frozen_string_literal: true

require "test_helper"

module Desk
  module CustomerSatisfaction
    class SurveyTest < ActiveSupport::TestCase
      def test_valid_customer_satisfaction_survey
        survey = create(:default_survey)

        assert survey.valid?
      end

      def test_invalid_customer_satisfaction_survey
        invalid_survey = ::Desk::CustomerSatisfaction::Survey.new

        assert_not invalid_survey.valid?
        assert_includes invalid_survey.errors.full_messages, "Organization must exist"
        assert_includes invalid_survey.errors.full_messages, "Name can't be blank"
        assert_includes invalid_survey.errors.full_messages, "Email state is not included in the list"
      end
    end
  end
end
