# frozen_string_literal: true

FactoryBot.define do
  factory :desk_ticket_follower, class: Desk::Ticket::Follower do
    association :user, factory: :user
    association :ticket, factory: :ticket
    kind { :subscriber }
  end
end
