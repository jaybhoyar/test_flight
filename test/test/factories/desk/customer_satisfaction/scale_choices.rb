# frozen_string_literal: true

FactoryBot.define do
  factory :desk_customer_satisfaction_scale_choice, class: ::Desk::CustomerSatisfaction::ScaleChoice do
    factory :default_question_scale_choice_1 do
      text { "Great" }
      display_order { 1 }
      slug { "happy" }
      association :question, factory: :default_question
    end

    factory :default_question_scale_choice_2 do
      text { "Neutral" }
      display_order { 2 }
      slug { "neutral" }
      association :question, factory: :default_question
    end

    factory :default_question_scale_choice_3 do
      text { "Not Good" }
      display_order { 3 }
      slug { "unhappy" }
      association :question, factory: :default_question
    end

    factory :thank_you_page_first_question_scale_choice_1 do
      text { "Easy" }
      display_order { 1 }
      slug { "happy" }
      association :question, factory: :thank_you_page_first_question
    end

    factory :thank_you_page_first_question_scale_choice_2 do
      text { "Not easy" }
      display_order { 2 }
      slug { "unhappy" }
      association :question, factory: :thank_you_page_first_question
    end

    factory :thank_you_page_second_question_scale_choice_1 do
      text { "Easy" }
      display_order { 1 }
      slug { "happy" }
      association :question, factory: :thank_you_page_second_question
    end

    factory :thank_you_page_second_question_scale_choice_2 do
      text { "Not easy" }
      display_order { 2 }
      slug { "unhappy" }
      association :question, factory: :thank_you_page_second_question
    end
  end
end
