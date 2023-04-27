# frozen_string_literal: true

require "test_helper"

module Desk
  class Twitter::Events::DirectMessageTest < ActiveSupport::TestCase
    def setup
      organization = create(:organization)
      details = ActiveSupport::HashWithIndifferentAccess.new(
        JSON.parse(file_fixture("twitter_dm.json").read)
      )
      @message = Twitter::Events::DirectMessage.new(details, organization)
    end

    def test_from
      author = @message.from

      assert_equal "User", author.class.name
      assert_equal "12340004", author.customer_detail.twitter_id
      assert_equal "Ashik Salman", author.name
      assert_equal "hi_ashik", author.customer_detail.twitter_screen_name
    end

    def test_subject
      assert_equal "Twitter DM for @bbzwhelp - Ashik Salman", @message.subject
    end

    def test_content
      assert_equal "Please give support for #NH123", @message.content
    end

    def test_in_reply_to_id
      assert_nil @message.in_reply_to_id
    end

    def test_message_id
      assert_equal "12350001", @message.message_id
    end

    def test_user_id
      assert_equal "12340004", @message.send(:user_id)
    end

    def test_user_name
      assert_equal "Ashik Salman", @message.send(:user_name)
    end

    def test_user_screen_name
      assert_equal "hi_ashik", @message.send(:user_screen_name)
    end
  end
end
