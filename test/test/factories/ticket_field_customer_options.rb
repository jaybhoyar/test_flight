# frozen_string_literal: true

FactoryBot.define do
  factory :ticket_field_customer_option do
    is_editable_by_agent { true }
  end
end
