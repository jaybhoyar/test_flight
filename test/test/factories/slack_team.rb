# frozen_string_literal: true

FactoryBot.define do

  factory :slack_team do
    association :organization
    team_id { Faker::Code.nric }
    team_name { Faker::Company.suffix }
    slack_user_id { Faker::Code.nric }
  end

end
