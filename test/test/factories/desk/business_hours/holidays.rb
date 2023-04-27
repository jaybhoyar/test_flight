# frozen_string_literal: true

FactoryBot.define do
  factory :holiday, class: ::Desk::BusinessHours::Holiday do
    name { "New Year" }
    date { Date.current }
    business_hour
  end
end
