# frozen_string_literal: true

FactoryBot.define do
  factory :desk_core_rule, class: ::Desk::Core::Rule do
    name { "Refund" }
    description { Faker::Lorem.paragraph }
    active { true }
    association :organization, factory: :organization

    factory :core_rule_with_data, class: ::Desk::Core::Rule do
      conditions { [build(:condition_subject_contains_refund)] }
    end
  end
end
