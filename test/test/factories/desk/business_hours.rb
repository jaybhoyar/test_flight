# frozen_string_literal: true

FactoryBot.define do
  factory :business_hour, class: Desk::BusinessHour do
    name { "Sales" }
    description { "Sales team's business hour starts late in the evening" }
    time_zone { "Eastern Time (US & Canada)" }
    organization

    trait :weekend do
      name { "Weekend" }
      schedules {
                  [
                    build(:schedule, :inactive, day: "Monday"),
                    build(:schedule, :inactive, day: "Tuesday"),
                    build(:schedule, :inactive, day: "Wednesday"),
                    build(:schedule, :inactive, day: "Thursday"),
                    build(:schedule, :inactive, day: "Friday"),
                    build(:schedule, :active, day: "Saturday"),
                    build(:schedule, :active, day: "Sunday")
                  ]
                }
    end
  end
end
