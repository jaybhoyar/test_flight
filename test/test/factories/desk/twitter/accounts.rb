# frozen_string_literal: true

FactoryBot.define do
  factory :twitter_account, class: Desk::Twitter::Account do
    env_name { "test" }
    oauth_status { "open" }

    association :organization, factory: :organization

    factory :valid_twitter_account do
      env_name { "test" }
      oauth_token { "valid_oauth_token" }
      oauth_token_secret { "valid_oauth_token_secret" }
      oauth_user_id { "123456" }
      screen_name { "valid_screen_name_1" }
      oauth_status { "active" }

      factory :active_twitter_account do
        oauth_user_id { "12340001" }
        screen_name { "bbzwhelp" }

        association :organization, factory: :org_spinkart
      end
    end

    factory :twitter_account_spinkart do
      env_name { "test" }
      oauth_user_id { "123456" }
      screen_name { "valid_screen_name_2" }
      association :organization, factory: :org_spinkart
    end
  end
end
