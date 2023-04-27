# frozen_string_literal: true

FactoryBot.define do
  factory :view, class: View do
    association :organization, factory: :organization
    association :record_visibility, factory: :record_visibility
    rule { build(:view_rule_with_data) }

    title { "Tickets with Subject Refund" }
    description { Faker::Lorem.paragraph }
  end
end
