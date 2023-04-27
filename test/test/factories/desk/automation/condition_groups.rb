# frozen_string_literal: true

FactoryBot.define do
  factory :automation_condition_group, class: Desk::Automation::ConditionGroup do
    association :rule, factory: :automation_rule

    join_type { "and_operator" }
    conditions_join_type { "and_operator" }

    trait :match_any do
      conditions_join_type { "or_operator" }
    end
    trait :match_all do
      conditions_join_type { "and_operator" }
    end
  end
end
