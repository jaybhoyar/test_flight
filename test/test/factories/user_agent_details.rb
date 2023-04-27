# frozen_string_literal: true

FactoryBot.define do
  factory :user_agent_detail do
    client_known { true }
    client_name { Faker::Lorem.word }
    client_full_version { Faker::Lorem.word }
    os_name { Faker::Lorem.word }
    os_full_version { Faker::Lorem.word }
    device_type { Faker::Lorem.word }
    device_name { Faker::Lorem.word }

    association :knowledge_base_view, factory: :kb_view
  end
end
