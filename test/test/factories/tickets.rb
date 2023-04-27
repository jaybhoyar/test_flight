# frozen_string_literal: true

FactoryBot.define do
  factory :ticket do
    association :agent, factory: :user
    association :requester, factory: :user
    association :group, factory: :group
    association :organization, factory: :organization

    subject { "Unable to generate invoice!" }
    agent_id { 2 }
    channel { "ui" }
    status { "open" }
    category { "Incident" }
    number { 1 }
    priority { 0 }

    factory :ticket_for_feature_request do
      subject { "Unable to generate reset password mail" }
      agent_id { 2 }
      channel { "ui" }
      status { "new" }
      category { "Feature Request" }
      number { 2 }
      priority { 1 }
    end

    factory :ticket_with_email_config do
      channel { "email" }
      association :email_configuration, factory: :email_configuration
    end

    factory :ticket_via_twitter do
      channel { "twitter" }
      association :agent, factory: :twitter_contact
    end

    trait :with_desc do
      after :create do |ticket, options|
        create :comment, comment_type: :description, ticket:, author: ticket.requester
      end
    end
  end
end
