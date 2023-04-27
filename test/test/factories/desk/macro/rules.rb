# frozen_string_literal: true

FactoryBot.define do
  factory :desk_macro_rule, class: Desk::Macro::Rule do
    transient do
      groups { [] }
      creator { create(:user) }
    end

    name { "Feedback" }
    description { Faker::Lorem.paragraph }
    active { true }
    association :organization, factory: :organization

    trait :visible_to_myself do
      after :create do |macro, options|
        create :desk_record_visibility, creator: options.creator, groups: options.groups, visibility: "myself",
          record: macro
      end
    end

    trait :visible_to_all_agents do
      after :create do |macro, options|
        create :desk_record_visibility, creator: options.creator, groups: options.groups, visibility: "all_agents",
          record: macro
      end
    end

    trait :visible_to_agent_groups do
      after :create do |macro, options|
        create :desk_record_visibility, creator: options.creator, groups: options.groups, visibility: "agent_groups",
          record: macro
      end
    end

    trait :system_generated do
      after :create do |macro, options|
        create :desk_record_visibility, creator: nil, groups: options.groups, visibility: "all_agents", record: macro
      end
    end
  end
end
