# frozen_string_literal: true

FactoryBot.define do
  factory :company_domain do
    name { "wayne.com" }
    association :company, factory: :company
  end
end
