# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    association :ticket, factory: :ticket
    association :author, factory: :user
    info { "Another Comment" }
    message_id { Faker::Internet.email }
    in_reply_to_id { Faker::Internet.email }

    trait :with_attachments do
      after :create do |comment|
        file = Rack::Test::UploadedFile.new("public/apple-touch-icon.png", "image/png")
        comment.attachments.attach(file)
      end
    end

    factory :description_comment do
      info { "First Comment" }
      comment_type { :description }
    end

    factory :twitter_comment do
      info { "@hi_neetodesk First Comment" }

      trait :with_tweet do
        channel_mode { "tweet" }
      end

      trait :with_twitter_dm do
        channel_mode { "direct_message" }
      end
    end

    trait :description do
      comment_type { :description }
    end

    trait :reply do
      comment_type { :reply }
    end

    trait :note do
      comment_type { :note }
    end
  end
end
