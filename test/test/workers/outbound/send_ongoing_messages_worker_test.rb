# frozen_string_literal: true

require "test_helper"

module Outbound
  class SendOngoingMessagesWorkerTest < ActiveSupport::TestCase
    require "sidekiq/testing"

    def setup
      travel_to DateTime.parse("4:00 PM IST")
      Sidekiq::Testing.fake!
      @organization = create(:organization)
      @user1 = create(:user, email: "joeseph@example.com", organization: @organization)
      @outbound_message = create(:outbound_message, organization: @organization, state: "Live")

      stub_request(:any, /fonts.googleapis.com/)
    end

    def teardown
      travel_back
    end

    def test_outbound_message_sent_to_all_users_falling_under_ongoing_category_with_delivery_window
      create(:desk_core_condition, verb: "any_time", field: "created_at", conditionable: @outbound_message.rule)

      outbound_delivery_window = create(
        :outbound_delivery_window, message_id: @outbound_message.id,
        time_zone: "New Delhi")
      schedule = create(
        :delivery_schedule, delivery_window: outbound_delivery_window, from: DateTime.parse("9:00 AM"),
        to: DateTime.parse("5:00 PM"))

      ActionMailer::Base.deliveries.clear
      SendOngoingMessagesWorker.new.perform

      assert_equal 1, ActionMailer::Base.deliveries.count
    end

    def test_outbound_message_sent_to_future_users_falling_under_ongoing_category_with_delivery_window
      create(
        :desk_core_condition, verb: "greater_than", field: "created_at", conditionable: @outbound_message.rule,
        value: nil)

      outbound_delivery_window = create(
        :outbound_delivery_window, message_id: @outbound_message.id,
        time_zone: "New Delhi")
      schedule = create(
        :delivery_schedule, delivery_window: outbound_delivery_window, from: DateTime.parse("9:00 AM"),
        to: DateTime.parse("5:00 PM"))

      @user1.update!(created_at: DateTime.current + 2.day)
      ActionMailer::Base.deliveries.clear
      SendOngoingMessagesWorker.new.perform

      assert_equal 1, ActionMailer::Base.deliveries.count
    end

    def test_outbound_message_not_sent_to_users_outside_the_delivery_window
      create(:desk_core_condition, verb: "any_time", field: "created_at", conditionable: @outbound_message.rule)

      outbound_delivery_window = create(:outbound_delivery_window, message_id: @outbound_message.id)
      schedule = create(
        :delivery_schedule, from: DateTime.current + 2.hours, to: DateTime.current + 8.hours,
        delivery_window: outbound_delivery_window)

      ActionMailer::Base.deliveries.clear
      SendOngoingMessagesWorker.new.perform

      assert_equal 0, ActionMailer::Base.deliveries.count
    end

    def test_ongoing_outbound_message_sent_to_all_users_when_no_condition_is_selected
      user2 = create(:user, email: "zen@example.com", organization: @organization)
      user3 = create(:user, email: "matt@example.com", organization: @organization)
      user4 = create(:user, email: "lincoln@example.com", organization: @organization)

      create(
        :desk_core_condition, verb: "any_time", field: "created_at", conditionable: @outbound_message.rule,
        value: nil)

      outbound_delivery_window = create(
        :outbound_delivery_window, message_id: @outbound_message.id,
        time_zone: "New Delhi")
      schedule = create(
        :delivery_schedule, delivery_window: outbound_delivery_window, from: DateTime.parse("9:00 AM"),
        to: DateTime.parse("5:00 PM"))

      ActionMailer::Base.deliveries.clear
      SendOngoingMessagesWorker.new.perform

      assert_equal 4, ActionMailer::Base.deliveries.count
    end

    def test_that_emails_are_not_sent_outside_timeframe
      user2 = create(:user, email: "zen@example.com", organization: @organization)
      user3 = create(:user, email: "matt@example.com", organization: @organization)
      user4 = create(:user, email: "lincoln@example.com", organization: @organization)

      create(
        :desk_core_condition, verb: "any_time", field: "created_at", conditionable: @outbound_message.rule,
        value: nil)

      outbound_delivery_window = create(
        :outbound_delivery_window, message_id: @outbound_message.id,
        time_zone: "New Delhi")
      schedule = create(
        :delivery_schedule, delivery_window: outbound_delivery_window, from: DateTime.parse("9:00 AM"),
        to: DateTime.parse("3:00 PM"))

      ActionMailer::Base.deliveries.clear
      SendOngoingMessagesWorker.new.perform

      assert_equal 0, ActionMailer::Base.deliveries.count
    end
  end
end
