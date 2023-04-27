# frozen_string_literal: true

FactoryBot.define do
  factory :desk_customer_satisfaction_survey_response, class: ::Desk::CustomerSatisfaction::SurveyResponse do
    comment { "Thank you." }
    association :ticket, factory: :ticket
    association :scale_choice, factory: :default_question_scale_choice_1
  end
end
