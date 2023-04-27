# frozen_string_literal: true

FactoryBot.define do
  factory :ticket_field_response, class: ::Desk::Ticket::Field::Response do
    association :ticket_field
    association :owner, factory: :ticket
    value { "Firefox" }

    trait :required do
      association :ticket_field, is_required: true
    end
  end
end
