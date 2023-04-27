# frozen_string_literal: true

require "test_helper"

module Desk
  module CustomerSatisfaction
    class SurveyResponseTest < ActiveSupport::TestCase
      def test_valid_customer_satisfaction_survey_response
        survey_response = create(:desk_customer_satisfaction_survey_response)

        assert survey_response.valid?
      end

      def test_invalid_customer_satisfaction_survey_response
        invalid_survey_response = ::Desk::CustomerSatisfaction::SurveyResponse.new

        assert_not invalid_survey_response.valid?
        assert_includes invalid_survey_response.errors.full_messages, "Ticket must exist"
      end
    end
  end
end
