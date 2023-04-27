# frozen_string_literal: true

FactoryBot.define do
  factory :desk_task_list, class: "Desk::Task::List" do
    association :organization

    name { Faker::Lorem.sentence }
    status { 0 }

    trait :with_data do
      name { "Refund Tasks" }
      after :create do |list|
        create :desk_task_item, list: list, name: "Check if the item was returned"
        create :desk_task_item, list: list, name: "Validate if return is processed"
        create :desk_task_item, list: list, name: "Talk to customer over phone"
        create :desk_task_item, list: list, name: "See if the item can be exchanged"
        create :desk_task_item, list:, name: "Forward ticket to billing team"
      end
    end
  end
end
