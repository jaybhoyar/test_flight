# frozen_string_literal: true

FactoryBot.define do
  factory :desk_core_event, class: ::Desk::Core::Event do
    name { :updated }
    association :rule, factory: :desk_core_rule
  end
end
