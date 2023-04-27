# frozen_string_literal: true

FactoryBot.define do
  factory :push_notification_subscription do
    user { create :user }
    unique_handle { Faker::Internet.uuid }
    factory :subscription_attributes do
      build_number { Faker::Device.build_number }
      manufacturer { Faker::Device.manufacturer }
      model_name { Faker::Device.model_name }
      serial { Faker::Device.serial }
    end
  end
end
