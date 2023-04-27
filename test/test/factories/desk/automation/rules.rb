# frozen_string_literal: true

FactoryBot.define do
  factory :automation_rule, class: Desk::Automation::Rule do
    name { "Refund" }
    description { Faker::Lorem.paragraph }
    active { true }
    performer { :any }
    association :organization, factory: :organization

    factory :automation_rule_with_data, class: Desk::Automation::Rule do
      events { [ build(:automation_event, name: "created") ] }

      after :create do |rule|
        group = create :automation_condition_group, rule: rule
        create :automation_condition, join_type: "and_operator", field: "subject", verb: "contains", value: "Refund",
          conditionable: group
        create :automation_action, rule:
      end
    end

    trait :on_ticket_create do
      events { [ build(:automation_event, name: "created") ] }
    end

    trait :on_ticket_update do
      events { [ build(:automation_event, name: "updated") ] }
    end

    trait :on_reply_added do
      events { [ build(:automation_event, name: "reply_added") ] }
    end

    trait :on_note_added do
      events { [ build(:automation_event, name: "note_added") ] }
    end

    trait :on_agent_updated do
      events { [ build(:automation_event, name: "agent_updated") ] }
    end

    trait :on_status_updated do
      events { [ build(:automation_event, name: "status_updated") ] }
    end

    trait :on_feedback_received do
      events { [ build(:automation_event, name: "feedback_received") ] }
    end

    trait :time_based do
      events { [ build(:automation_event, name: "time_based") ] }
    end
  end
end
