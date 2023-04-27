# frozen_string_literal: true

FactoryBot.define do
  factory :link_contact_detail do
    value { "https//dribble.com/ethan_hunt" }
    association :user, factory: :user
  end
end
