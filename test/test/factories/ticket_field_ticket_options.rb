# frozen_string_literal: true

FactoryBot.define do
  factory :ticket_field_ticket_option do
    is_required_for_agent_when_closing_ticket { false }
  end
end
