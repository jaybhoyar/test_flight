# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    # Manually create data for tests
    skip_assign_role { true }

    association :organization, factory: :organization
    status { "invited" }
    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { generate_password }
    continue_assigning_tickets { true }

    # association :role, factory: :organization_role_agent

    factory :user_with_admin_role do
      after :create do |user, evaluator|
        admin_role = user.organization.roles.find_by(name: "Admin")
        user.role = admin_role || create(:organization_role_admin, organization: user.organization)
        user.save!
      end
    end

    factory :user_with_agent_role do
      after :create do |user, evaluator|
        agent_role = user.organization.roles.find_by(name: "Agent")
        user.role = agent_role || create(:organization_role_agent, organization: user.organization)
        user.save!
      end
    end

    trait :agent do
      after :create do |user, evaluator|
        agent_role = user.organization.roles.find_by(name: "Agent")
        user.role = agent_role || create(:organization_role_agent, organization: user.organization)
        user.save!
      end
    end

    trait :admin do
      after :create do |user, evaluator|
        admin_role = user.organization.roles.find_by(name: "Admin")
        user.role = admin_role || create(:organization_role_admin, organization: user.organization)
        user.save!
      end
    end
  end
end

def generate_password
  "Ou1#{Faker::Internet.password(min_length: 10, max_length: 20, mix_case: true, special_characters: true)}"
end
