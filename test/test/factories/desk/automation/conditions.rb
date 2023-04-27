# frozen_string_literal: true

FactoryBot.define do
  factory :automation_condition, class: Desk::Automation::Condition do
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

  factory :automation_condition_subject_contains_refund, class: Desk::Automation::Condition do
    join_type { "and_operator" }
    field { "subject" }
    verb { "contains" }
    value { "Refund" }
  end

  factory :automation_condition_subject_equals_refund, class: Desk::Automation::Condition do
    join_type { "and_operator" }
    field { "subject" }
    verb { "is" }
    value { "Refund" }
  end

  factory :automation_condition_subject_is_not_refund, class: Desk::Automation::Condition do
    join_type { "and_operator" }
    field { "subject" }
    verb { "is_not" }
    value { "refund" }
  end

  factory :automation_condition_subject_does_not_contain_refund, class: Desk::Automation::Condition do
    join_type { "and_operator" }
    field { "subject" }
    verb { "does_not_contain" }
    value { "refund" }
  end

  factory :automation_condition_subject_contains_urgent, class: Desk::Automation::Condition do
    join_type { "and_operator" }
    field { "subject" }
    verb { "contains" }
    value { "urgent" }
  end
end
