# frozen_string_literal: true

require "test_helper"
class Desk::Outbound::MailServiceTest < ActiveSupport::TestCase
  def setup
    travel_to DateTime.parse("6:00 PM")
    stub_request(:any, /fonts.googleapis.com/)
  end

  def teardown
    travel_back
  end

  def test_outbound_message_when_sending_broadcast_messages
    travel_back
    travel_to DateTime.parse("4:30 AM") # 10:00 AM IST

    outbound_message = build(:outbound_message)
    outbound_message.message_type = "broadcast"
    outbound_message.save!
    outbound_message.update!(waiting_for_delivery_window: true)

    outbound_delivery_window = create(
      :outbound_delivery_window, message_id: outbound_message.id,
      time_zone: "New Delhi")
    schedule = create(
      :delivery_schedule, delivery_window: outbound_delivery_window, from: DateTime.parse("9:00 AM"),
      to: DateTime.parse("5:00 PM"))

    Desk::Outbound::MailService.new(outbound_message.id).process
    outbound_message.reload
    assert_equal "broadcast", outbound_message.message_type
    assert_equal "Sent", outbound_message.state
  end

  def test_outbound_message_when_sending_broadcast_messages_doesnt_update_before_time
    travel_back
    travel_to DateTime.parse("3:00 AM") # 08:30 AM IST

    outbound_message = build(:outbound_message)
    outbound_message.message_type = "broadcast"
    outbound_message.save!
    outbound_message.update!(waiting_for_delivery_window: true)

    outbound_delivery_window = create(
      :outbound_delivery_window, message_id: outbound_message.id,
      time_zone: "New Delhi")
    schedule = create(
      :delivery_schedule, delivery_window: outbound_delivery_window, from: DateTime.parse("9:00 AM"),
      to: DateTime.parse("5:00 PM"))

    Desk::Outbound::MailService.new(outbound_message.id).process
    outbound_message.reload
    assert_equal "broadcast", outbound_message.message_type
    assert_equal "Draft", outbound_message.state
  end

  def test_broadcast_is_not_sent_when_created
    travel_back
    travel_to DateTime.parse("6:00 PM IST")

    outbound_message = build(:outbound_message)
    outbound_message.message_type = "broadcast"
    outbound_message.save!
    outbound_message.update!(waiting_for_delivery_window: true)

    outbound_delivery_window = create(:outbound_delivery_window, message_id: outbound_message.id, time_zone: "Mumbai")

    create(
      :delivery_schedule, delivery_window: outbound_delivery_window, from: DateTime.parse("9:00 AM"),
      to: DateTime.parse("5:00 PM"))

    Desk::Outbound::MailService.new(outbound_message.id).process
    outbound_message.reload
    assert_equal "broadcast", outbound_message.message_type
    assert_equal "Draft", outbound_message.state
  end

  def test_outbound_message_when_sending_test_email
    outbound_message = create(:outbound_message)
    Desk::Outbound::MailService.new(outbound_message.id, ["hello@spinkart.com"]).process
    outbound_message.reload
    assert_equal "Draft", outbound_message.state
  end

  def test_outbound_message_when_sending_ongoing_messages
    outbound_message = create(:outbound_message)
    outbound_message.state = "Live"
    outbound_message.save!
    Desk::Outbound::MailService.new(outbound_message.id).process
    outbound_message.reload
    assert_equal "ongoing", outbound_message.message_type
    assert_equal "Live", outbound_message.state
  end

  def test_message_events_create_success_after_delivery
    user = create(:user)
    organization = user.organization
    outbound_message = build(:outbound_message, organization:)
    outbound_message.message_type = "broadcast"
    outbound_message.update!(waiting_for_delivery_window: true)
    outbound_message.save!

    outbound_delivery_window = create(:outbound_delivery_window, message_id: outbound_message.id)
    schedule = create(
      :delivery_schedule, from: DateTime.current - 5.hours, to: DateTime.current + 2.hours,
      delivery_window: outbound_delivery_window)

    contact = user

    assert_difference "::Outbound::MessageEvent.count", 1 do
      Desk::Outbound::MailService.new(outbound_message.id).process
    end

    assert_equal ::Outbound::MessageEvent.last.user_id, contact.id
    assert_equal ::Outbound::MessageEvent.last.message_id, outbound_message.id
  end

  def test_waiting_for_delivery_window_changes_after_sending_broadcast_messages
    travel_back
    travel_to DateTime.parse("4:30 AM") # 10:00 AM IST

    outbound_message = build(:outbound_message)
    outbound_message.update!(message_type: "broadcast")
    outbound_message.update!(waiting_for_delivery_window: true)

    outbound_delivery_window = create(
      :outbound_delivery_window, message_id: outbound_message.id,
      time_zone: "New Delhi")
    schedule = create(
      :delivery_schedule, delivery_window: outbound_delivery_window, from: DateTime.parse("9:00 AM"),
      to: DateTime.parse("5:00 PM"))

    Desk::Outbound::MailService.new(outbound_message.id).process
    outbound_message.reload
    assert_equal "broadcast", outbound_message.message_type
    assert_equal "Sent", outbound_message.state
    assert_equal false, outbound_message.waiting_for_delivery_window
  end

  def test_repeated_messages_not_sent_to_users_for_ongoing_campaign
    user = create(:user)
    outbound_message = build(:outbound_message, organization: user.organization)
    outbound_message.update!(waiting_for_delivery_window: true, message_type: "ongoing")

    outbound_delivery_window = create(:outbound_delivery_window, message_id: outbound_message.id)
    schedule = create(
      :delivery_schedule, from: DateTime.current - 5.hours, to: DateTime.current + 2.hours,
      delivery_window: outbound_delivery_window)

    assert_difference "::Outbound::MessageEvent.count", 1 do
      Desk::Outbound::MailService.new(outbound_message.id).process
    end

    assert_equal ::Outbound::MessageEvent.last.user_id, user.id
    assert_equal ::Outbound::MessageEvent.last.message_id, outbound_message.id

    assert_difference "::Outbound::MessageEvent.count", 0 do
      Desk::Outbound::MailService.new(outbound_message.id).process
    end
  end

  def test_messages_are_sent_to_existing_and_future_users_of_ongoing_campaign
    organization = create(:organization)

    # Rule with no conditions.
    rule = create(:outbound_message_rule, organization:)
    outbound_message = setup_outbound_message(rule, ::Outbound::Message.audience_types[:existing_and_new_users])

    past_user = create(:user, organization:, created_at: 2.days.ago)
    future_user = create(:user, organization:, created_at: 7.days.from_now)

    assert_difference "::Outbound::MessageEvent.count", 2 do
      Desk::Outbound::MailService.new(outbound_message.id).process
    end

    notified_recipients = outbound_message.notified_recipients

    assert notified_recipients.include?(past_user)
    assert notified_recipients.include?(future_user)

    # Update Rule with a condition.
    create(:outbound_condition_email_contains_joe, conditionable: rule, sequence: 1)
    joe_past_user = create(
      :user, email: "joesmith@bigbinary.com", organization:,
      created_at: 3.days.ago)
    joe_future_user = create(
      :user, email: "joey@bigbinary.com", organization:,
      created_at: 4.days.from_now)

    assert_difference "::Outbound::MessageEvent.count", 2 do
      Desk::Outbound::MailService.new(outbound_message.id).process
    end

    notified_recipients = outbound_message.notified_recipients

    assert notified_recipients.include?(joe_past_user)
    assert notified_recipients.include?(joe_future_user)
  end

  def test_messages_are_sent_to_future_users_of_ongoing_campaign
    organization = create(:organization)
    rule = create(:outbound_message_rule, organization:)
    outbound_message = setup_outbound_message(rule, ::Outbound::Message.audience_types[:new_users_only])

    past_user = create(:user, organization:, created_at: 2.days.ago)
    future_user = create(:user, organization:, created_at: 7.days.from_now)

    assert_difference "::Outbound::MessageEvent.count", 1 do
      Desk::Outbound::MailService.new(outbound_message.id).process
    end

    assert_not outbound_message.notified_recipients.include?(past_user)
    assert_equal ::Outbound::MessageEvent.last.user_id, future_user.id

    create(:outbound_condition_email_contains_joe, conditionable: rule, sequence: 1)
    joe_past_user = create(
      :user, email: "joesmith@bigbinary.com", organization:,
      created_at: 3.days.ago)
    joe_future_user = create(
      :user, email: "joey@bigbinary.com", organization:,
      created_at: 4.days.from_now)

    assert_difference "::Outbound::MessageEvent.count", 1 do
      Desk::Outbound::MailService.new(outbound_message.id).process
    end
    assert ::Outbound::MessageEvent.pluck(:user_id).include?(joe_future_user.id)
  end

  def test_message_sent_to_all_if_rule_not_present
    outbound_message = create(:outbound_message, rule: nil, waiting_for_delivery_window: true)
    user1 = create(:user, organization: outbound_message.organization)
    user2 = create(:user, organization: outbound_message.organization)

    outbound_delivery_window = create(:outbound_delivery_window, message_id: outbound_message.id)
    create(
      :delivery_schedule, from: DateTime.current - 5.hours, to: DateTime.current + 2.hours,
      delivery_window: outbound_delivery_window)

    assert_difference "::Outbound::MessageEvent.count", 2 do
      Desk::Outbound::MailService.new(outbound_message.id).process
    end

    notified_recipients = outbound_message.notified_recipients

    assert notified_recipients.include?(user1)
    assert notified_recipients.include?(user2)
  end

  private

    def setup_outbound_message(rule, audience_type)
      outbound_message = create(
        :outbound_message, {
          waiting_for_delivery_window: true,
          audience_type:,
          rule:,
          organization: rule.organization
        })

      outbound_delivery_window = create(:outbound_delivery_window, message_id: outbound_message.id)
      create(
        :delivery_schedule, from: DateTime.current - 5.hours, to: DateTime.current + 2.hours,
        delivery_window: outbound_delivery_window)
      outbound_message
    end
end
