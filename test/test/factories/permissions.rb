# frozen_string_literal: true

FactoryBot.define do
  factory :permission, class: Permission do
    name { "desk.view_tickets" }
    category { "Desk" }
    description { "View all tickets" }

    trait :view_tickets do
      name { "desk.view_tickets" }
      category { "Desk" }
      description { "View all tickets" }
    end

    trait :manage_tickets do
      name { "desk.manage_tickets" }
      category { "Desk" }
      description { "Manage all tickets" }
    end

    factory :customer_view_permissions, class: Permission do
      name { "customer.view_customer_details" }
      category { "Customer" }
      description { "View Customer details" }
    end
  end
end
