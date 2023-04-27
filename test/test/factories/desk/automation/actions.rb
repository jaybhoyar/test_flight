# frozen_string_literal: true

FactoryBot.define do
  factory :automation_action, class: Desk::Automation::Action do
    name { "change_ticket_status" }
    status { "closed" }
    association :rule, factory: :automation_rule

    trait :reply do
      name { "email_to_requester" }
      subject { "Hi we have started working on a ticket created by you." }
      body { Faker::Lorem.paragraph }
    end
  end
end
