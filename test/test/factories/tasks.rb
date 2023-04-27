# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    association :ticket

    name { Faker::Lorem.sentence }
  end
end
