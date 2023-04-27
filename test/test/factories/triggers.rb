# frozen_string_literal: true

FactoryBot.define do
  factory :trigger do
    slug { Faker::Internet.slug }
    description { Faker::Lorem.paragraph }
    active { true }
  end
end
