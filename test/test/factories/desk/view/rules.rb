# frozen_string_literal: true

FactoryBot.define do
  factory :view_rule, class: View::Rule do
    association :organization, factory: :organization
    association :view, factory: :view

    name { "Refund" }
  end
end
