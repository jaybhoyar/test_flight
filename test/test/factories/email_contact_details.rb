# frozen_string_literal: true

FactoryBot.define do
  factory :email_contact_detail do
    value { Faker::Internet.email }
    association :user, factory: :user
  end
end
