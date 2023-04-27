# frozen_string_literal: true

FactoryBot.define do
  factory :view_rule_with_data, class: View::Rule do
    name { "Tickets subject contains Refund" }
    description { Faker::Lorem.paragraph }
    association :organization, factory: :organization
    conditions { [build(:automation_condition_subject_contains_refund)] }
  end
end
