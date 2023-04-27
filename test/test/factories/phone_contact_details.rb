# frozen_string_literal: true

FactoryBot.define do
  factory :phone_contact_detail do
    value { "9111111111" }
    association :user, factory: :user
  end
end
