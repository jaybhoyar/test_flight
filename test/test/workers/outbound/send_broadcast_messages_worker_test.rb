# frozen_string_literal: true

require "test_helper"

module Outbound
  class SendBroadcastMessagesWorkerTest < ActiveSupport::TestCase
    require "sidekiq/testing"

    def setup
      travel_to DateTime.parse("6:00 PM")
      Sidekiq::Testing.fake!
      @organization = create(:organization)

      @user1 = create(:user, email: "murphy@example.com", organization: @organization)
      @user2 = create(:user, email: "christopher@example.com", organization: @organization)
      @user3 = create(:user, email: "chris@example.com", organization: @organization)

      @outbound_message = create(
        :outbound_message, organization: @organization, state: "Draft",
        message_type: "broadcast", waiting_for_delivery_window: true)
    end

    def teardown
      travel_back
    end

    def test_send_outbound_broadcast_message_with_delivery_window
      travel_back
      travel_to DateTime.parse("4:00 PM IST")
      create(
        :outbound_condition, conditionable: @outbound_message.rule, field: "email", verb: "contains",
        value: "chris")

      outbound_delivery_window = create(
        :outbound_delivery_window, message_id: @outbound_message.id,
        time_zone: "New Delhi")
      schedule = create(
        :delivery_schedule, delivery_window: outbound_delivery_window, from: DateTime.parse("9:00 AM"),
        to: DateTime.parse("5:00 PM"))

      stub_request(:any, /fonts.googleapis.com/)

      ActionMailer::Base.deliveries.clear
      SendBroadcastMessagesWorker.new.perform

      assert_equal 2, ActionMailer::Base.deliveries.count
    end

    def test_emails_are_not_sent_outbound_broadcast_message_with_delivery_window
      travel_back
      travel_to DateTime.parse("6:00 PM IST")
      create(
        :outbound_condition, conditionable: @outbound_message.rule, field: "email", verb: "contains",
        value: "chris")

      outbound_delivery_window = create(
        :outbound_delivery_window, message_id: @outbound_message.id,
        time_zone: "New Delhi")
      schedule = create(
        :delivery_schedule, delivery_window: outbound_delivery_window, from: DateTime.parse("9:00 AM"),
        to: DateTime.parse("5:00 PM"))

      ActionMailer::Base.deliveries.clear
      SendBroadcastMessagesWorker.new.perform

      assert_equal 0, ActionMailer::Base.deliveries.count
    end

    def test_outbound_broadcast_message_not_sent_outside_delivery_window
      create(
        :outbound_condition, conditionable: @outbound_message.rule, field: "email", verb: "contains",
        value: "murphy@example.com")

      outbound_delivery_window = create(:outbound_delivery_window, message_id: @outbound_message.id)
      schedule = create(
        :delivery_schedule, from: DateTime.now + 2.hours, to: DateTime.now + 4.hours,
        delivery_window: outbound_delivery_window)

      ActionMailer::Base.deliveries.clear
      SendBroadcastMessagesWorker.new.perform

      assert_equal 0, ActionMailer::Base.deliveries.count
    end

    def test_outbound_broadcast_message_not_sent_if_not_queued
      outbound_message = create(
        :outbound_message, organization: @organization, state: "Draft",
        message_type: "broadcast", waiting_for_delivery_window: false)

      create(
        :outbound_condition, conditionable: outbound_message.rule, field: "email", verb: "contains",
        value: "chris@example.com")

      outbound_delivery_window = create(:outbound_delivery_window, message_id: outbound_message.id)
      schedule = create(:delivery_schedule, delivery_window: outbound_delivery_window)

      ActionMailer::Base.deliveries.clear
      SendBroadcastMessagesWorker.new.perform

      assert_equal 0, ActionMailer::Base.deliveries.count
    end

    def test_outbound_message_sent_to_all_users_when_no_condition_is_selected
      create(
        :desk_core_condition, verb: "any_time", field: "created_at", conditionable: @outbound_message.rule,
        value: nil)

      outbound_delivery_window = create(:outbound_delivery_window, message_id: @outbound_message.id)
      schedule = create(
        :delivery_schedule, delivery_window: outbound_delivery_window, from: DateTime.now - 5.hours,
        to: DateTime.now + 2.hours)

      stub_request(:any, /fonts.googleapis.com/)

      ActionMailer::Base.deliveries.clear
      SendBroadcastMessagesWorker.new.perform

      assert_equal 3, ActionMailer::Base.deliveries.count
    end
  end
end
