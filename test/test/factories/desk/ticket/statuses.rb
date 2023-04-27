# frozen_string_literal: true

FactoryBot.define do
  factory :desk_ticket_status, class: Desk::Ticket::Status do
    association :organization, factory: :organization

    agent_label { Faker::Lorem.word }
    customer_label { Faker::Lorem.word }
    name { Faker::Lorem.word }

    trait :closed do
      name { "closed" }
      agent_label { "Closed" }
      customer_label { "Closed" }
    end

    trait :waiting_on_customer do
      name { "waiting_on_customer" }
      agent_label { "Waiting on Customer" }
      customer_label { "Waiting on Customer" }
    end
  end
end
