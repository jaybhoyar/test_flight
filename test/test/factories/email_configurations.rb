# frozen_string_literal: true

FactoryBot.define do
  factory :email_configuration do
    email { "hello" }
    association :organization, factory: :organization
    # forward_to_email { "hello" }
    from_name { "organization_name" }
    primary { true }

    factory :email_config_spinkart do
      email { "help" }
      association :organization, factory: :org_spinkart
      # forward_to_email { "help" }
    end
  end
end
