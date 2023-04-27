# frozen_string_literal: true

FactoryBot.define do
  factory :forward_email do
    email { Faker::Internet.email }
    association :comment, factory: :comment
  end
end
