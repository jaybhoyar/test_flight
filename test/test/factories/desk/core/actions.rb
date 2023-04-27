# frozen_string_literal: true

FactoryBot.define do
  factory :desk_core_action, class: ::Desk::Core::Action do
    name { "action_name" }
    association :rule, factory: :desk_core_rule
  end
end
