# frozen_string_literal: true

FactoryBot.define do
  factory :desk_macro_action, class: Desk::Macro::Action do
    name { "add_reply" }
    association :rule, factory: :desk_macro_rule

    trait :reply do
      name { "add_reply" }
      body { Faker::Lorem.paragraph }
    end
  end
end
