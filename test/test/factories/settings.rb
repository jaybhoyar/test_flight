# frozen_string_literal: true

FactoryBot.define do
  factory :setting, class: ::Setting do
    association :organization, factory: :organization
    base_url { Faker::Internet.url }
    tickets_email_footer_content {
      <<~HTML
      —
      TICKETS EMAIL FOOTER CONTENT
      HTML
    }
  end
end
