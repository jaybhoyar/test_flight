# frozen_string_literal: true

FactoryBot.define do
  factory :ticket_field_option, class: ::Desk::Ticket::Field::Option do
    association :ticket_field, :dropdown
    sequence(:name) { |n| "Option #{n}" }
    display_order { 0 }
  end
end
