# frozen_string_literal: true

require "test_helper"

module Desk
  class Twitter::Events::TweetTest < ActiveSupport::TestCase
    def setup
      @organization = create(:organization)
      details = ActiveSupport::HashWithIndifferentAccess.new(
        JSON.parse(file_fixture("tweet.json").read)
      )
      @tweet = Twitter::Events::Tweet.new(details[:tweet_create_events].first, @organization)
    end

    def test_from
      author = @tweet.from

      assert_equal "User", author.class.name
      assert_equal "12340004", author.customer_detail.twitter_id
      assert_equal "Ashik Salman", author.name
      assert_equal "hi_ashik", author.customer_detail.twitter_screen_name
    end

    def test_subject
      assert_equal "Tweet for @bbzwhelp - Ashik Salman", @tweet.subject
    end

    def test_content
      assert_equal "@bbzwhelp Please resolve my issue #NH123", @tweet.content
    end

    def test_in_reply_to_id
      assert_nil @tweet.in_reply_to_id
    end

    def test_message_id
      assert_equal "12340002", @tweet.message_id
    end

    def test_user_id
      assert_equal "12340004", @tweet.send(:user_id)
    end

    def test_user_name
      assert_equal "Ashik Salman", @tweet.send(:user_name)
    end

    def test_user_screen_name
      assert_equal "hi_ashik", @tweet.send(:user_screen_name)
    end
  end
end
