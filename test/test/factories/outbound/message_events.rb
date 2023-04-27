# frozen_string_literal: true

FactoryBot.define do
  factory :message_event, class: Outbound::MessageEvent do
    association :message, factory: :outbound_message
    association :user, factory: :user
    association :email_contact_detail, factory: :email_contact_detail
  end
end
