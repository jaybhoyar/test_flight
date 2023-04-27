# frozen_string_literal: true

FactoryBot.define do
  factory :customer_detail do
    association :user, factory: :user
  end
end
