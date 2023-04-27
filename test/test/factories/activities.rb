# frozen_string_literal: true

FactoryBot.define do
  factory :activity do
    association :owner, factory: :user
    association :trackable, factory: :ticket
    key { "activity.ticket.create" }
    action { "New ticket created" }
  end
end
