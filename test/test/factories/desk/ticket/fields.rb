# frozen_string_literal: true

FactoryBot.define do
  factory :ticket_field, class: ::Desk::Ticket::Field do
    association :organization, factory: :organization
    agent_label { "Please mention the browser agent_label" }
    kind { ::Desk::Ticket::Field.kinds[:text] }
    is_required { false }
    display_order { 0 }

    trait :textarea do
      agent_label { "Please mention the details about computer you are using" }
      kind { ::Desk::Ticket::Field.kinds[:textarea] }
    end

    trait :number do
      agent_label { "How many times did you face this issue?" }
      kind { ::Desk::Ticket::Field.kinds[:number] }
    end

    trait :float do
      agent_label { "The invoice total of your organization is" }
      kind { ::Desk::Ticket::Field.kinds[:float] }
    end

    trait :date do
      agent_label { "When was it occurred last time" }
      kind { ::Desk::Ticket::Field.kinds[:date] }
    end

    trait :dropdown do
      agent_label { "Please select make of your computer" }
      kind { ::Desk::Ticket::Field.kinds[:dropdown] }

      after(:build) do |field, evaluator|
        field.ticket_field_options << build(:ticket_field_option, name: "Chrome", ticket_field: field)
      end
    end

    trait :multi_select do
      agent_label { "Which of these products you have purchased before" }
      kind { ::Desk::Ticket::Field.kinds["multi-select"] }

      ticket_field_options { create_list(:ticket_field_option, 5) }
    end

    trait :system_subject do
      agent_label { "Please mention the subject" }
      kind { :system_subject }
      is_system { true }
    end

    trait :system_status do
      kind { :system_status }
      agent_label { "Status" }
      customer_label { "Status" }
      is_system { true }
    end

    trait :system_agent do
      kind { :system_agent }
      agent_label { "Agent" }
      customer_label { "Agent" }
      is_system { true }
    end

    trait :system_group do
      kind { :system_group }
      agent_label { "Group" }
      customer_label { "Group" }
      is_system { true }
    end

    trait :system_category do
      kind { :system_category }
      agent_label { "Category" }
      customer_label { "Category" }
      is_system { true }
    end

    trait :system_subject do
      kind { :system_subject }
      agent_label { "Subject" }
      customer_label { "Subject" }
      is_system { true }
    end
  end
end
