# frozen_string_literal: true

require "test_helper"

class Desk::Ticket::Comment::TwitterReplyServiceTest < ActiveSupport::TestCase
  class TweetCommentTest < ActiveSupport::TestCase
    def setup
      @user = create :user
      @organization = @user.organization
      @details = ActiveSupport::HashWithIndifferentAccess.new(
        JSON.parse(file_fixture("tweet.json").read)
      )
      @details.merge!(event_type: "tweet_create_events")
      @tweet = ::Desk::Twitter::Events::Tweet.new(@details[:tweet_create_events].first, @organization)
      @twitter_account = create(:twitter_account_spinkart, organization: @organization)
      @ticket = Desk::Integrations::Twitter::TicketHandlerService.new(*tweet_data, fetch_options(true)).run
      @activity = Desk::Integrations::Twitter::ActivityService.new(@ticket, @tweet.message_id, @details).create_activity
    end

    def test_process_for_tweet_comment
      @comment = @ticket.comments.create!(comment_params)
      Desk::Ticket::Comment::TwitterReplyService.any_instance.expects(:send_tweet).returns(
        id_str: "12360002", event_type: "tweet_create_events"
      )
      Desk::Ticket::Comment::TwitterReplyService.any_instance.expects(:send_direct_message).never
      activity = Desk::Ticket::Comment::TwitterReplyService.new(@ticket, @comment).process
      @comment.reload

      assert_equal "@hi_ashik Reply Comment", @comment.info
      assert_equal "12360001", @comment.in_reply_to_id
      assert_equal "12360002", @comment.message_id
      assert_equal "reply", @comment.comment_type
      assert_equal "tweet", @comment.channel_mode

      assert_equal @ticket.id, activity.ticket_id
      assert_equal "12360002", activity.activity_id
    end

    def test_process_for_tweet_comment
      comment_params.merge!(channel_mode: "direct_message")
      @comment = @ticket.comments.create!(comment_params)

      Desk::Ticket::Comment::TwitterReplyService.any_instance.expects(:send_direct_message).returns(
        id_str: "12360002", event_type: "direct_message_events"
      )
      Desk::Ticket::Comment::TwitterReplyService.any_instance.expects(:send_tweet).never
      activity = Desk::Ticket::Comment::TwitterReplyService.new(@ticket, @comment).process
      @comment.reload

      assert_equal "Reply Comment", @comment.info.to_plain_text
      assert_equal "12360001", @comment.in_reply_to_id
      assert_equal "12360002", @comment.message_id
      assert_equal "reply", @comment.comment_type
      assert_equal "direct_message", @comment.channel_mode

      assert_equal @ticket.id, activity.ticket_id
      assert_equal "12360002", activity.activity_id
    end

    def test_reply_tweet_comment_info
      @comment = @ticket.comments.create!(comment_params)

      Twitter::REST::Client.any_instance.expects(:update).with(
        "@hi_ashik Reply Comment", in_reply_to_status_id: "12340002"
      ).returns(Twitter::Tweet.new(
        id: "12360002", in_reply_to_user_id_str: "12340002",
        user: { id_str: "12340004" }))

      options = Desk::Ticket::Comment::TwitterReplyService.new(@ticket, @comment).send_tweet(@twitter_account)
    end

    def test_reply_dm_comment_info
      comment_params.merge!(channel_mode: "direct_message")
      @comment = @ticket.comments.create!(comment_params)

      Twitter::REST::Client.any_instance.expects(:create_direct_message).with(
        "12340004", "Reply Comment"
      ).returns(Twitter::DirectMessage.new(id: "12360002"))

      options = Desk::Ticket::Comment::TwitterReplyService.new(@ticket, @comment).send_direct_message(@twitter_account)
    end

    private

      def tweet_data
        [
          @tweet.from,
          @tweet.subject,
          @tweet.content,
          @twitter_account.organization,
          @tweet.in_reply_to_id,
          @tweet.message_id,
          @tweet.attachments
        ]
      end

      def fetch_options(new_ticket)
        {
          new_ticket:, event_type: "tweet_create_events",
          channel: "twitter", channel_mode: "tweet", parent_comment: nil
        }
      end

      def comment_params
        @_comment_params ||= {
          info: "Reply Comment",
          author: @user,
          in_reply_to_id: "12360001",
          message_id: nil,
          comment_type: "reply",
          channel_mode: "tweet"
        }
      end
  end
end
