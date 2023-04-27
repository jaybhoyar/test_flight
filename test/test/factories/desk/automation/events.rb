# frozen_string_literal: true

FactoryBot.define do
  factory :automation_event, class: Desk::Automation::Event do
    name { :updated }
    association :rule, factory: :automation_rule
  end
end
