# frozen_string_literal: true

FactoryBot.define do
  factory :desk_customer_satisfaction_question, class: Desk::CustomerSatisfaction::Question do
    factory :default_question do
      text { "How would you rate your overall satisfaction for the resolution provided by the agent?" }
      point_scale { 3 }
      default { true }
      display_order { 1 }
      association :survey, factory: :default_survey
    end

    factory :thank_you_page_first_question do
      text { "How easy was it to get in touch with our Customer Support?" }
      point_scale { 2 }
      default { false }
      display_order { 2 }
      association :survey, factory: :default_survey
    end

    factory :thank_you_page_second_question do
      text { "How easy was it for you to get your issue resolved?" }
      point_scale { 2 }
      default { false }
      display_order { 3 }
      association :survey, factory: :default_survey
    end
  end
end
