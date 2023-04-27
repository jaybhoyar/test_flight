# frozen_string_literal: true

require "test_helper"

class Desk::Integrations::Twitter::ActivityServiceTest < ActiveSupport::TestCase
  def setup
    @details = ActiveSupport::HashWithIndifferentAccess.new(
      JSON.parse(file_fixture("tweet.json").read)
    )
    @details.merge!(event_type: "tweet_create_events")
  end

  def test_create_activity_success
    ticket = create(:ticket)
    @service = Desk::Integrations::Twitter::ActivityService.new(ticket, "12340002", @details)
    activity = @service.create_activity

    assert_equal "12340001", activity.for_user_id
    assert_equal "12340002", activity.activity_id
    assert_equal "tweet_create_events", activity.event_type
    assert_equal @details, activity.details
  end

  def test_create_activity_failure
    @service = Desk::Integrations::Twitter::ActivityService.new(nil, "12340002", @details)
    assert_nil @service.create_activity
  end
end
