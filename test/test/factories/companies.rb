# frozen_string_literal: true

FactoryBot.define do
  factory :company do
    name { "Wayne Corp" }
    association :organization, factory: :organization
  end
end
