# frozen_string_literal: true

require "test_helper"

class Desk::Integrations::Twitter::EventHandlers::DirectMessageServiceTest < ActiveSupport::TestCase
  def setup
    @details = ActiveSupport::HashWithIndifferentAccess.new(
      JSON.parse(file_fixture("twitter_dm.json").read)
    )
    @details.merge!(event_type: "direct_message_events")
    @twitter_account = create(:active_twitter_account)
    @service = ::Desk::Integrations::Twitter::EventHandlers::DirectMessageService.new(@details)
  end

  def test_perform_method
    @service.expects(:process_direct_message_event).at_most_once.returns("ticket")
    @service.expects(:create_activity_record).with("ticket").at_most_once.returns("true")
    result = @service.perform
    assert_equal "true", result
  end

  def test_process_direct_message_event
    ticket = create(:ticket)
    @message = ::Desk::Twitter::Events::DirectMessage.new(@details, @twitter_account.organization)

    mock_object = mock("object")

    ::Desk::Twitter::Events::DirectMessage.any_instance.expects(:from).returns("contact")
    @service.expects(:organization).returns("organization")
    data = [
      "contact",
      @message.subject,
      @message.content,
      "organization",
      @message.in_reply_to_id,
      @message.message_id,
      @message.attachments
    ]
    mock_object.expects(:run).at_most_once.returns(ticket)
    Desk::Integrations::Twitter::TicketHandlerService.expects(:new).with(
      *data, @service.send(:fetch_options)
    ).at_least_once.returns(mock_object)

    result = @service.send(:process_direct_message_event)
    assert_equal ticket, result
  end

  def test_create_activity_record
    ticket = create(:ticket)
    activity = @service.send(:create_activity_record, ticket)
    assert_equal "12340001", activity.for_user_id
    assert_equal "12350001", activity.activity_id
    assert_equal "direct_message_events", activity.event_type
    assert_equal @details, activity.details
  end

  def test_create_activity_record_failure
    assert_nil @service.send(:create_activity_record, nil)
  end

  def test_data_values
    sample_data = [
      "contact",
      "Twitter DM for @bbzwhelp - Ashik Salman",
      "Please give support for #NH123",
      "organization",
      nil,
      "12350001",
      []
    ]

    ::Desk::Twitter::Events::DirectMessage.any_instance.expects(:from).returns("contact")
    @service.expects(:organization).returns("organization")

    assert_equal sample_data, @service.send(:data)
  end

  def test_fetch_options
    sample_options = {
      new_ticket: true, event_type: "direct_message_events",
      channel: "twitter", channel_mode: "direct_message", parent_comment: nil
    }
    assert_equal sample_options, @service.send(:fetch_options)
  end

  def test_organization
    organization = @twitter_account.organization
    assert_equal organization, @service.send(:organization)
  end

  def test_duplicate_event
    ticket = create(:ticket)

    assert_not @service.send(:duplicate_event?)
    @service.expects(:process_direct_message_event).at_most_once.returns(ticket)

    @service.perform
    assert @service.send(:duplicate_event?)
  end

  def test_dm_into_tickets_disabled_false
    ticket = create(:ticket)

    assert_equal false, @service.send(:dm_into_tickets_disabled?)
    Desk::Integrations::Twitter::TicketHandlerService.any_instance.expects(:run).at_most_once.returns(ticket)
    @service.perform
  end

  def test_dm_into_tickets_disabled_true
    ticket = create(:ticket)

    @twitter_account.update!(convert_dm_into_ticket: false)
    @twitter_account.reload
    assert_equal true, @service.send(:dm_into_tickets_disabled?)
    Desk::Integrations::Twitter::TicketHandlerService.any_instance.expects(:run).never
    @service.perform
  end

  def test_new_ticket
    assert_equal true, @service.send(:new_ticket?)

    ticket = create(:ticket)
    activity = @service.send(:create_activity_record, ticket)

    assert_equal false, @service.send(:new_ticket?)

    activity.update!(created_at: Time.current - 2.days)
    activity.reload

    assert_equal true, @service.send(:new_ticket?)
  end

  def test_exceeded_dm_ticket_threading_interval
    ticket = create(:ticket)
    activity = @service.send(:create_activity_record, ticket)

    assert_equal false, @service.send(:exceeded_dm_ticket_threading_interval?, activity)

    activity.update!(created_at: Time.current - 2.days)
    activity.reload

    assert_equal true, @service.send(:exceeded_dm_ticket_threading_interval?, activity)
  end
end
