# frozen_string_literal: true

require "test_helper"

class Desk::Integrations::Twitter::EventHandlers::TweetCreateServiceTest < ActiveSupport::TestCase
  def setup
    @twitter_account = create(:active_twitter_account)

    @organization = @twitter_account.organization
    @details = ActiveSupport::HashWithIndifferentAccess.new(
      JSON.parse(file_fixture("tweet.json").read)
    )
    @details.merge!(event_type: "tweet_create_events")
    @service = ::Desk::Integrations::Twitter::EventHandlers::TweetCreateService.new(@details)
    @tweet = ::Desk::Twitter::Events::Tweet.new(@details[:tweet_create_events].first, @organization)
  end

  def test_perform_method
    @service.expects(:process_tweet_event).at_most_once.returns("ticket")
    result = @service.expects(:create_activity_record).with("ticket").at_most_once.returns("true")
    result = @service.perform
    assert_equal "true", result
  end

  def test_process_tweet_event
    ticket = create(:ticket)
    mock_object = mock("object")

    Desk::Twitter::Events::Tweet.any_instance.expects(:from).returns("contact")
    @service.expects(:organization).returns("organization")
    data = [
      "contact",
      @tweet.subject,
      @tweet.content,
      "organization",
      @tweet.in_reply_to_id,
      @tweet.message_id,
      @tweet.attachments
    ]
    mock_object.expects(:run).at_most_once.returns(ticket)
    Desk::Integrations::Twitter::TicketHandlerService.expects(:new).with(
      *data, @service.send(:fetch_options)
    ).at_least_once.returns(mock_object)

    result = @service.send(:process_tweet_event)
    assert_equal ticket, result
  end

  def test_create_activity_record
    ticket = create(:ticket)
    activity = @service.send(:create_activity_record, ticket)
    assert_equal "12340001", activity.for_user_id
    assert_equal "12340002", activity.activity_id
    assert_equal "tweet_create_events", activity.event_type
    assert_equal @details, activity.details
  end

  def test_create_activity_record_failure
    assert_nil @service.send(:create_activity_record, nil)
  end

  def test_data_values
    sample_data = [
      "contact",
      "Tweet for @bbzwhelp - Ashik Salman",
      "@bbzwhelp Please resolve my issue #NH123",
      "organization",
      nil,
      "12340002",
      []
    ]

    Desk::Twitter::Events::Tweet.any_instance.expects(:from).returns("contact")
    @service.expects(:organization).returns("organization")

    assert_equal sample_data, @service.send(:data)
  end

  def test_fetch_options
    sample_options = {
      new_ticket: true, event_type: "tweet_create_events",
      channel: "twitter", channel_mode: "tweet", parent_comment: nil
    }
    assert_equal sample_options, @service.send(:fetch_options)
  end

  def test_organization
    assert_equal @organization, @service.send(:organization)
  end

  def test_duplicate_event
    ticket = create(:ticket)

    assert_not @service.send(:duplicate_event?)
    @service.expects(:process_tweet_event).at_most_once.returns(ticket)

    @service.perform
    assert @service.send(:duplicate_event?)
  end

  def test_new_ticket
    assert @service.send(:new_ticket?)

    data = @details[:tweet_create_events].first

    in_reply_to_status_id_str = "valid_sid"

    new_details = @details
    new_details[:tweet_create_events][0][:in_reply_to_status_id_str] = in_reply_to_status_id_str

    create :comment, message_id: in_reply_to_status_id_str

    @service = ::Desk::Integrations::Twitter::EventHandlers::TweetCreateService.new(new_details)

    assert_not @service.send(:new_ticket?)
  end
end
