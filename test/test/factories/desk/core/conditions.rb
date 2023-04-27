# frozen_string_literal: true

FactoryBot.define do
  factory :desk_core_condition, class: ::Desk::Core::Condition do
    association :conditionable, factory: :automation_rule

    join_type { "and_operator" }
    field { "subject" }
    verb { "contains" }
    value { "Refund" }

    trait :any do
      join_type { "and_operator" }
      field { "created_at" }
      verb { "any_time" }
      value { "" }
    end

    trait :time_based do
      kind { :time_based }
    end

    trait :tags do
      kind { :tags }
    end
  end
end
