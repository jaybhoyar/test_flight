# frozen_string_literal: true

require "test_helper"

class OutboundMessageMailerTest < ActionMailer::TestCase
  setup do
    travel_to DateTime.parse("6:00 PM")
    organization = create(:organization)
    @user1 = create(:user, email: "joeseph@example.com", organization:)
    @user2 = create(:user, email: "joey@example.com", organization:)
    @user3 = create(:user, email: "oliver@example.com", organization:)

    @outbound_message = create(:outbound_message, organization:)
    @outbound_message1 = create(
      :outbound_message, organization:,
      message_type: "broadcast")

    stub_request(:any, /fonts.googleapis.com/)
  end

  def teardown
    travel_back
  end

  def test_outbound_message_mailer
    contact_details = @user1.email_contact_details.first
    subject = @outbound_message.email_subject
    body = @outbound_message.email_content.body.to_s

    email = OutboundMessageMailer
      .with(organization_name: @outbound_message.organization.name)
      .new_outbound_message(@outbound_message, subject, body, contact_details)
      .deliver

    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email.subject, @outbound_message.email_subject
    outbound_message_org_user = @outbound_message.organization.users.find(@user1.id)
    assert_includes outbound_message_org_user.email_contact_details.pluck(:value), email.to.first
    assert_equal ["notification.staging@neeto.com"], email.from
  end

  def test_outbound_message_mailer_with_bcc_setting
    setting = @user1.organization.setting
    setting.update(auto_bcc: true, bcc_email: "test@example.com")

    contact_details = @user1.email_contact_details.first
    subject = @outbound_message.email_subject
    body = @outbound_message.email_content.body.to_s

    email = OutboundMessageMailer
      .with(organization_name: @outbound_message.organization.name)
      .new_outbound_message(@outbound_message, subject, body, contact_details)
      .deliver

    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email.subject, @outbound_message.email_subject
    outbound_message_org_user = @outbound_message.organization.users.find(@user1.id)
    assert_includes outbound_message_org_user.email_contact_details.pluck(:value), email.to.first
    assert_equal ["notification.staging@neeto.com"], email.from
    assert_equal ["bb@test.com", "bb@best.com", "test@example.com"], email.bcc
  end

  def test_outbound_message_not_sent_for_unsubscribed_contacts
    @user1.update!(has_active_email_subscription: false)
    @user2.update!(has_active_email_subscription: false)
    @user3.update!(has_active_email_subscription: false)
    Desk::Outbound::MailService.new(@outbound_message.id).process

    assert ActionMailer::Base.deliveries.empty?
  end

  def test_outbound_message_sent_to_users_based_on_rule
    condition = create(:outbound_condition_email_contains_joe, conditionable: @outbound_message.rule)

    outbound_delivery_window = create(:outbound_delivery_window, message_id: @outbound_message.id)
    schedule = create(
      :delivery_schedule, from: DateTime.current - 5.hours, to: DateTime.current + 2.hours,
      delivery_window: outbound_delivery_window)

    Desk::Outbound::MailService.new(@outbound_message.id).process
    assert_equal 2, ActionMailer::Base.deliveries.count
  end

  def test_ongoing_outbound_message_sent_to_existing_users_based_on_rule
    create :outbound_condition, conditionable: @outbound_message.rule, field: "created_at", verb: "any_time"
    create(:outbound_condition_email_contains_joe, conditionable: @outbound_message.rule)

    outbound_delivery_window = create(:outbound_delivery_window, message_id: @outbound_message.id)
    schedule = create(
      :delivery_schedule, from: DateTime.current - 5.hours, to: DateTime.current + 2.hours,
      delivery_window: outbound_delivery_window)

    Desk::Outbound::MailService.new(@outbound_message.id).process

    assert_equal 2, ActionMailer::Base.deliveries.count
  end

  def test_ongoing_outbound_message_sent_to_future_signed_in_users_based_on_rule
    create :outbound_condition, conditionable: @outbound_message.rule, field: "created_at", verb: "greater_than"
    create(:outbound_condition_email_contains_joe, conditionable: @outbound_message.rule)

    outbound_delivery_window = create(:outbound_delivery_window, message_id: @outbound_message.id)
    schedule = create(
      :delivery_schedule, from: DateTime.current - 5.hours, to: DateTime.current + 2.hours,
      delivery_window: outbound_delivery_window)

    Desk::Outbound::MailService.new(@outbound_message.id).process

    assert_equal 0, ActionMailer::Base.deliveries.count
  end

  def test_mailer_success_for_broadcast_outbound_message_with_email_contains_condition
    create(:outbound_condition_email_contains_oliver, conditionable: @outbound_message1.rule)
    contact = ::Desk::Core::RuleUsersFinder.new(@outbound_message.rule).matching_users.first

    contact_params = contact.email_contact_details.first

    outbound_delivery_window = create(:outbound_delivery_window, message_id: @outbound_message1.id)
    schedule = create(
      :delivery_schedule, from: DateTime.current - 5.hours, to: DateTime.current + 2.hours,
      delivery_window: outbound_delivery_window)

    subject = @outbound_message1.email_subject
    body = @outbound_message1.email_content.body.to_s

    email = OutboundMessageMailer
      .with(organization_name: @outbound_message1.organization.name)
      .new_outbound_message(@outbound_message1, subject, body, contact_params)
      .deliver

    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email.subject, @outbound_message1.email_subject
    assert_equal [contact_params[:value]], email.to
  end

  def test_mailer_success_for_broadcast_outbound_message_with_multiple_conditions
    create(:outbound_condition_email_contains_oliver, conditionable: @outbound_message1.rule)
    create(:outbound_condition_email_is_joey, conditionable: @outbound_message1.rule, join_type: "or_operator")

    subject = @outbound_message1.email_subject
    body = @outbound_message1.email_content.body.to_s

    contacts = ::Desk::Core::RuleUsersFinder.new(@outbound_message1.rule).matching_users

    contacts.each do |contact|
      contact_params = contact.email_contact_details.first
      email = OutboundMessageMailer
        .with(organization_name: @outbound_message1.organization.name)
        .new_outbound_message(@outbound_message1, subject, body, contact_params)
        .deliver

      assert_includes email.subject, @outbound_message1.email_subject
      assert_equal [contact_params[:value]], email.to
    end
  end

  def test_ongoing_outbound_message_for_future_signed_in_users_condition
    rule = create(:outbound_message_rule, organization: @user1.organization)
    outbound_message = create(
      :outbound_message, {
        waiting_for_delivery_window: true,
        audience_type: Outbound::Message.audience_types[:new_users_only],
        rule:,
        organization: @user1.organization
      })

    @user1.update!(created_at: Time.current + 2.day)
    condition = create(
      :outbound_condition, value: nil, verb: "greater_than", field: "created_at",
      conditionable: outbound_message.rule)

    outbound_delivery_window = create(:outbound_delivery_window, message_id: outbound_message.id)
    schedule = create(
      :delivery_schedule, from: DateTime.current - 5.hours, to: DateTime.current + 2.hours,
      delivery_window: outbound_delivery_window)

    Desk::Outbound::MailService.new(outbound_message.id).process

    assert_equal 1, ActionMailer::Base.deliveries.count
  end

  def test_mailer_success_for_outbound_message_with_no_condition
    condition = create(
      :outbound_condition, value: nil, verb: "any_time", field: "created_at",
      conditionable: @outbound_message.rule)

    outbound_delivery_window = create(:outbound_delivery_window, message_id: @outbound_message.id)
    schedule = create(
      :delivery_schedule, from: DateTime.current - 5.hours, to: DateTime.current + 2.hours,
      delivery_window: outbound_delivery_window)

    Desk::Outbound::MailService.new(@outbound_message.id).process

    assert_equal 3, ActionMailer::Base.deliveries.count
  end
end
