# frozen_string_literal: true

FactoryBot.define do
  factory :delivery_schedule, class: Outbound::DeliveryWindow::Schedule do
    day { DateTime.current.strftime("%A") }
    status { 1 }
    from { DateTime.current - 2.hours }
    to { DateTime.current + 2.hours }
    association :delivery_window, factory: :outbound_delivery_window

    trait :active do
      status { 1 }
    end

    trait :inactive do
      status { 0 }
    end
  end
end
