# frozen_string_literal: true

FactoryBot.define do
  factory :desk_customer_satisfaction_survey, class: ::Desk::CustomerSatisfaction::Survey do
    name { "Survey" }

    factory :default_survey do
      name { "Default Survey" }
      enabled { true }
      default { true }
      association :organization, factory: :organization
      email_state { "closed_ticket" }
    end

    factory :another_survey do
      name { Faker::Name.unique.name }
      enabled { true }
      association :organization, factory: :organization
      email_state { "closed_ticket" }
    end
  end
end
