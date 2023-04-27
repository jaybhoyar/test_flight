# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    skip_seed_data { true }

    name { "BigBinary" }
    api_key { "orgoneapikey" }
    sequence(:subdomain) { |n| "#{name.parameterize}-#{n}" }
    is_onboard { true }

    after(:create) do |org, evaluator|
      org.setting || create(:setting, organization: org)
    end

    factory :org_spinkart do
      name { "SpinKart" }
      api_key { "spinkartapikey" }
    end

    factory :org_eventsinindia do
      name { "EventsInIndia" }
      api_key { "eventsinindiaapikey" }
    end
  end
end
