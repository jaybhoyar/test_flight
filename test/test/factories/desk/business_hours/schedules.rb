# frozen_string_literal: true

FactoryBot.define do
  factory :schedule, class: ::Desk::BusinessHours::Schedule do
    day { ::Desk::BusinessHours::Schedule::DAYS_NAMES.sample }
    status { 1 }
    from { Time.utc(2000, 1, 1, 9, 00).utc }
    to { Time.utc(2000, 1, 1, 18, 00).utc }
    business_hour

    trait :active do
      status { 1 }
    end

    trait :inactive do
      status { 0 }
    end
  end
end
