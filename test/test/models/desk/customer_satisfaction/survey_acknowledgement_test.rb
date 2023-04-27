# frozen_string_literal: true

require "test_helper"

module Desk
  module CustomerSatisfaction
    class SurveyAcknowledgementTest < ActiveSupport::TestCase
      def test_valid_customer_satisfaction_survey_acknowledgement
        survey_acknowledgement = create(:default_survey_acknowlegement)

        assert survey_acknowledgement.valid?
      end

      def test_invalid_customer_satisfaction_survey
        invalid_survey_acknowledgement = ::Desk::CustomerSatisfaction::SurveyAcknowledgement.new

        assert_not invalid_survey_acknowledgement.valid?
        assert_includes invalid_survey_acknowledgement.errors.full_messages, "Text can't be blank"
      end
    end
  end
end
