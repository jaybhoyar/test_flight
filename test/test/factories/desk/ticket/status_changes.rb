# frozen_string_literal: true

FactoryBot.define do
  factory :desk_ticket_status_change, class: Desk::Ticket::StatusChange do
    association :ticket
    status { "new" }
  end
end
