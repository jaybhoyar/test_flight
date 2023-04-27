# frozen_string_literal: true

FactoryBot.define do
  factory :desk_task_item, class: "Desk::Task::Item" do
    association :list, factory: :desk_task_list

    name { Faker::Lorem.sentence }
    info { nil }
  end
end
