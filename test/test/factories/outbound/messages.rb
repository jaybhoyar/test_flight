# frozen_string_literal: true

FactoryBot.define do
  factory :outbound_message, class: Outbound::Message do
    association :organization, factory: :organization
    state { "Draft" }
    message_type { "ongoing" }
    title { Faker::Lorem.sentence }
    email_subject { Faker::Lorem.sentence }
    email_content { Faker::Lorem.paragraph }

    association :rule, factory: :outbound_message_rule
  end

  factory :outbound_broadcast_message, class: Outbound::Message do
    association :organization, factory: :organization
    state { "Draft" }
    message_type { "broadcast" }
    title { Faker::Lorem.sentence }
    email_subject { Faker::Lorem.sentence }
    email_content { Faker::Lorem.paragraph }

    association :rule, factory: :outbound_message_rule
  end
end
