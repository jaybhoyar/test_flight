# frozen_string_literal: true

FactoryBot.define do
  factory :group_member do
    association :group, factory: :group
    association :user, factory: :user
  end
end
