# frozen_string_literal: true

FactoryBot.define do
  factory :outbound_condition, class: Outbound::Condition do
    association :conditionable, factory: :automation_rule

    join_type { "and_operator" }
    field { "subject" }
    verb { "contains" }
    value { "Refund" }
  end

  factory :outbound_condition_email_contains_joe, class: Outbound::Condition do
    join_type { "and_operator" }
    field { "email" }
    verb { "contains" }
    value { "joe" }
  end

  factory :outbound_condition_email_contains_oliver, class: Outbound::Condition do
    join_type { "and_operator" }
    field { "email" }
    verb { "contains" }
    value { "oliver" }
  end

  factory :outbound_condition_email_is_joey, class: Outbound::Condition do
    join_type { "or_operator" }
    field { "email" }
    verb { "is" }
    value { "joey@example.com" }
  end

  factory :outbound_condition_last_sign_in_is_less_than_3days, class: Outbound::Condition do
    join_type { "and_operator" }
    field { "last_sign_in_at" }
    verb { "less_than" }
    value { "3" }
  end

  factory :outbound_condition_since_sign_up_is_greater_than_4days, class: Outbound::Condition do
    join_type { "and_operator" }
    field { "created_at" }
    verb { "greater_than" }
    value { "4" }
  end

  factory :outbound_condition_created_at_any_time, class: Outbound::Condition do
    join_type { "and_operator" }
    field { "created_at" }
    verb { "any_time" }
    value { nil }
  end
end
