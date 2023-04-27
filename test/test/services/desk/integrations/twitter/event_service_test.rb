# frozen_string_literal: true

require "test_helper"

class Desk::Integrations::Twitter::EventServiceTest < ActiveSupport::TestCase
  def setup
    @twitter_account = create(:active_twitter_account)

    @organization = @twitter_account.organization
    @details = JSON.parse(file_fixture("tweet.json").read)
    @details.merge!(event_type: "tweet_create_events")
    @event_service = Desk::Integrations::Twitter::EventService.new(@details)
  end

  def test_handle_event_for_tweet_create_events
    Desk::Integrations::Twitter::EventHandlers::TweetCreateService
      .any_instance
      .expects(:perform)
      .at_most_once.returns("true")

    result = @event_service.handle_event
    assert_equal "true", result
  end

  def test_event_type
    assert_equal "tweet_create_events", @event_service.send(:event_type)
  end
end
