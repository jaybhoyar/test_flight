# frozen_string_literal: true

FactoryBot.define do
  factory :round_robin_agent_slot do
    association :organization, factory: :organization
    association :user, factory: :user
    association :group, factory: :group
  end
end
