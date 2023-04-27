# frozen_string_literal: true

FactoryBot.define do
  factory :twitter_webhook, class: Desk::Twitter::Webhook do
    env_name { "test" }
    url { "https://sample.com/desk/webhooks/twitter" }

    factory :valid_twitter_webhook do
      env_name { "test" }
      url { "https://sample.com/desk/webhooks/twitter" }
      webhook_id { "123456" }
      valid_webhook { true }
    end
  end
end
