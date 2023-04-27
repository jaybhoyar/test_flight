# frozen_string_literal: true

FactoryBot.define do
  factory :customer_tag, class: Desk::Tag::CustomerTag do
    association :organization, factory: :organization
    name { Faker::Name.name }
  end
end
