# frozen_string_literal: true

FactoryBot.define do
  factory :organization_role do
    association :organization, factory: :organization

    name { Faker::Name.name }
    description { Faker::Lorem.sentence }
    kind { "system" }

    trait :user_defined do
      kind { "user_defined" }
    end

    factory :user_defined_role do
      kind { "user_defined" }
    end

    factory :organization_role_admin do
      name { "Admin" }
      description { Faker::Lorem.sentence }
      kind { "system" }
    end

    factory :organization_role_agent do
      name { "Agent" }
      description { Faker::Lorem.sentence }
      kind { "system" }
    end
  end
end
