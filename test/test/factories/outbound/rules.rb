# frozen_string_literal: true

FactoryBot.define do
  factory :outbound_message_rule, class: Outbound::Rule do
    name { "Refund" }
    description { Faker::Lorem.paragraph }
    association :organization

    factory :outbound_message_rule_with_data, class: Outbound::Rule do
      conditions { [build(:outbound_condition)] }
    end
  end
end
