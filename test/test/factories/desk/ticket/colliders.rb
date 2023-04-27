# frozen_string_literal: true

FactoryBot.define do
  factory :desk_ticket_collider, class: Desk::Ticket::Collider do
    association :user, factory: :user
    association :ticket, factory: :ticket
    kind { :view }
  end
end
