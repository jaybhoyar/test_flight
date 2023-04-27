# frozen_string_literal: true

FactoryBot.define do
  factory :group do
    name { Faker::Name.name }
    description { Faker::Lorem.paragraph }
    business_hour
    association :organization, factory: :organization
  end
end
