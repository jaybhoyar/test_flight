# frozen_string_literal: true

FactoryBot.define do
  factory :desk_customer_satisfaction_survey_acknowlegement,
    class: ::Desk::CustomerSatisfaction::SurveyAcknowledgement do

    factory :default_survey_acknowlegement do
      text { "Thank you for your valuable feedback" }
      association :survey, factory: :default_survey
    end
  end
end
