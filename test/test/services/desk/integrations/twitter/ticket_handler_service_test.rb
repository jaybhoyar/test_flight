# frozen_string_literal: true

require "test_helper"

class Desk::Integrations::Twitter::TicketHandlerServiceTest < ActiveSupport::TestCase
  # Test coverage when tweet events are handled
  class TweetCreateEventTest < ActiveSupport::TestCase
    def setup
      @twitter_account = create(:twitter_account_spinkart)
      @details = ActiveSupport::HashWithIndifferentAccess.new(
        JSON.parse(file_fixture("tweet.json").read)
      )
      @tweet = ::Desk::Twitter::Events::Tweet.new(@details[:tweet_create_events].first, @twitter_account.organization)
    end

    def test_new_ticket_service
      mock_object = mock("object")
      Desk::Ticketing::TicketCreatorService.expects(:new).with(
        @tweet.from, "Tweet for @bbzwhelp - Ashik Salman", "@bbzwhelp Please resolve my issue #NH123",
        @twitter_account.organization, nil, nil, "12340002",
        {
          new_ticket: true,
          channel: "twitter",
          event_type: "tweet_create_events",
          channel_mode: "tweet",
          attachments: [],
          status: "new"
        }
      ).at_most_once.returns(mock_object)
      mock_object.expects(:run).at_most_once.returns("true")

      service = Desk::Integrations::Twitter::TicketHandlerService.new(*sample_data, fetch_options(true))
      result = service.run
      assert_equal "true", result
    end

    def test_new_ticket_comment_service
      mock_object = mock("object")
      Desk::Integrations::Twitter::TicketHandlerService.any_instance.expects(:parent_comment).returns("parent_comment")
      Desk::Ticketing::TicketCommentCreatorService.expects(:new).with(
        "parent_comment", @tweet.from, "@bbzwhelp Please resolve my issue #NH123", "12340002",
        new_ticket: false, channel: "twitter", event_type: "tweet_create_events",
        channel_mode: "tweet", attachments: [], status: "new"
      ).at_most_once.returns(mock_object)
      mock_object.expects(:run).at_most_once.returns("true")

      service = Desk::Integrations::Twitter::TicketHandlerService.new(*sample_data, fetch_options(false))
      result = service.run
      assert_equal "true", result
    end

    def test_success_ticket_creation
      service = Desk::Integrations::Twitter::TicketHandlerService.new(*tweet_data, fetch_options(true))
      ticket = service.run
      comment = ticket.comments.first
      requester = ticket.requester

      assert_equal ticket.organization_id, @twitter_account.organization_id
      assert_equal "Tweet for @bbzwhelp - Ashik Salman", ticket.subject
      assert_equal "twitter", ticket.channel
      assert_equal "User", ticket.requester_type
      assert_equal "None", ticket.category
      assert_equal "low", ticket.priority
      assert_equal "new", ticket.status

      assert_equal "@bbzwhelp Please resolve my issue #NH123", comment.info.to_plain_text
      assert_equal "12340002", comment.message_id
      assert_equal "User", comment.author_type
      assert_equal "tweet", comment.channel_mode
      assert comment.latest
      assert_nil comment.in_reply_to_id

      assert_equal "Ashik Salman", requester.name
      assert_equal "12340004", requester.customer_detail.twitter_id
      assert_equal "hi_ashik", requester.customer_detail.twitter_screen_name
    end

    def test_success_ticket_comment_creation
      ticket_service = Desk::Integrations::Twitter::TicketHandlerService.new(*tweet_data, fetch_options(true))
      ticket = ticket_service.run

      details = ActiveSupport::HashWithIndifferentAccess.new(
        JSON.parse(file_fixture("tweet_comment.json").read)
      )

      @tweet = ::Desk::Twitter::Events::Tweet.new(details[:tweet_create_events].first, @twitter_account.organization)

      options = fetch_options(false).merge(parent_comment: ticket.comments.first)
      comment_service = Desk::Integrations::Twitter::TicketHandlerService.new(*tweet_data, options)
      comment = comment_service.run
      author = comment.author

      assert_equal 2, ticket.comments.count

      assert_equal "@bbzwhelp Any update ?", comment.info.to_plain_text
      assert_equal "12340102", comment.message_id
      assert_equal "12340002", comment.in_reply_to_id
      assert_equal "User", comment.author_type
      assert_equal "tweet", comment.channel_mode
      assert comment.latest

      assert_equal "Ashik Salman", author.name
      assert_equal "12340004", author.customer_detail.twitter_id
      assert_equal "hi_ashik", author.customer_detail.twitter_screen_name
    end

    private

      def sample_data
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
          channel: "twitter", channel_mode: "tweet"
        }
      end
  end

  # Test coverage when direct message events are handled
  class DirectMessageEventTest < ActiveSupport::TestCase
    def setup
      @twitter_account = create(:twitter_account_spinkart)
      @details = ActiveSupport::HashWithIndifferentAccess.new(
        JSON.parse(file_fixture("twitter_dm.json").read)
      )
      @message = ::Desk::Twitter::Events::DirectMessage.new(@details, @twitter_account.organization)
    end

    def test_new_ticket_service
      @twitter_account = create(:twitter_account)
      mock_object = mock("object")
      Desk::Ticketing::TicketCreatorService.expects(:new).with(
        @message.from, "Twitter DM for @bbzwhelp - Ashik Salman", "Please give support for #NH123",
        @twitter_account.organization, nil, nil, "12350001",
        {
          new_ticket: true,
          channel: "twitter",
          event_type: "direct_message_events",
          channel_mode: "direct_message",
          attachments: [],
          status: "new"
        }
      ).at_most_once.returns(mock_object)
      mock_object.expects(:run).at_most_once.returns("true")

      service = Desk::Integrations::Twitter::TicketHandlerService.new(*sample_data, fetch_options(true))
      result = service.run
      assert_equal "true", result
    end

    def test_new_ticket_comment_service
      mock_object = mock("object")
      Desk::Integrations::Twitter::TicketHandlerService.any_instance.expects(:parent_comment).returns("parent_comment")
      Desk::Ticketing::TicketCommentCreatorService.expects(:new).with(
        "parent_comment", @message.from, "Please give support for #NH123", "12350001",
        {
          new_ticket: false,
          channel: "twitter",
          event_type: "direct_message_events",
          channel_mode: "direct_message",
          attachments: [],
          status: "new"
        }
      ).at_most_once.returns(mock_object)
      mock_object.expects(:run).at_most_once.returns("true")

      service = Desk::Integrations::Twitter::TicketHandlerService.new(*sample_data, fetch_options(false))
      result = service.run
      assert_equal "true", result
    end

    def test_success_ticket_creation
      service = Desk::Integrations::Twitter::TicketHandlerService.new(*twitter_dm_data, fetch_options(true))
      ticket = service.run
      comment = ticket.comments.first
      requester = ticket.requester

      assert_equal ticket.organization_id, @twitter_account.organization_id
      assert_equal "Twitter DM for @bbzwhelp - Ashik Salman", ticket.subject
      assert_equal "twitter", ticket.channel
      assert_equal "User", ticket.requester_type
      assert_equal "None", ticket.category
      assert_equal "low", ticket.priority
      assert_equal "new", ticket.status

      assert_equal "Please give support for #NH123", comment.info.to_plain_text
      assert_equal "12350001", comment.message_id
      assert_equal "User", comment.author_type
      assert_equal "direct_message", comment.channel_mode
      assert comment.latest
      assert_nil comment.in_reply_to_id

      assert_equal "Ashik Salman", requester.name
      assert_equal "12340004", requester.customer_detail.twitter_id
      assert_equal "hi_ashik", requester.customer_detail.twitter_screen_name
    end

    def test_success_ticket_comment_creation
      ticket_service = Desk::Integrations::Twitter::TicketHandlerService.new(*twitter_dm_data, fetch_options(true))
      ticket = ticket_service.run
      ticket.twitter_activities.create!(
        for_user_id: "12340004",
        event_type: "direct_message_events",
        activity_id: "12350001"
      )

      @details[:direct_message_events].first[:id] = "12350002"
      @details[:direct_message_events].first[:message_create][:message_data][:text] = "Please give update"
      @message = ::Desk::Twitter::Events::DirectMessage.new(@details, @twitter_account.organization)

      options = fetch_options(false).merge(parent_comment: ticket.comments.first)
      comment_service = Desk::Integrations::Twitter::TicketHandlerService.new(*twitter_dm_data, options)
      comment = comment_service.run
      author = comment.author

      assert_equal 2, ticket.comments.count

      assert_equal "Please give update", comment.info.to_plain_text
      assert_equal "12350002", comment.message_id
      assert_equal "12350001", comment.in_reply_to_id
      assert_equal "User", comment.author_type
      assert_equal "direct_message", comment.channel_mode
      assert comment.latest

      assert_equal "Ashik Salman", author.name
      assert_equal "12340004", author.customer_detail.twitter_id
      assert_equal "hi_ashik", author.customer_detail.twitter_screen_name
    end

    # private

    def sample_data
      [
        @message.from,
        @message.subject,
        @message.content,
        @twitter_account.organization,
        @message.in_reply_to_id,
        @message.message_id,
        @message.attachments
      ]
    end

    def twitter_dm_data
      [
        @message.from,
        @message.subject,
        @message.content,
        @twitter_account.organization,
        @message.in_reply_to_id,
        @message.message_id,
        @message.attachments
      ]
    end

    def fetch_options(new_ticket)
      {
        new_ticket:, event_type: "direct_message_events",
        channel: "twitter", channel_mode: "direct_message"
      }
    end
  end
end
