# frozen_string_literal: true

FactoryBot.define do
  factory :ticket_tag, class: Desk::Tag::TicketTag do
    association :organization, factory: :organization
    name { Faker::Name.name }
  end
end
