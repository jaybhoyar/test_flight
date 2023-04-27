# frozen_string_literal: true

FactoryBot.define do
  factory :execution_log_entry, class: Desk::Automation::ExecutionLogEntry do
    association :rule, factory: :automation_rule
    association :ticket, factory: :ticket
  end
end
