# frozen_string_literal: true

FactoryBot.define do
  factory :outbound_delivery_window, class: Outbound::DeliveryWindow do
    name { "9-5 Weekdays" }
    time_zone { "Eastern Time (US & Canada)" }
    association :message, factory: :outbound_message

    trait :weekday do
      name { "Weekday" }
      schedules {
        [
          create(:delivery_schedule, :active, day: "Monday"),
          create(:delivery_schedule, :active, day: "Tuesday"),
          create(:delivery_schedule, :active, day: "Wednesday"),
          create(:delivery_schedule, :active, day: "Thursday"),
          create(:delivery_schedule, :active, day: "Friday"),
          create(:delivery_schedule, :inactive, day: "Saturday"),
          create(:delivery_schedule, :inactive, day: "Sunday")
        ]
      }
    end
  end
end
