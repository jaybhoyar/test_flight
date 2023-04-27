# frozen_string_literal: true

require "test_helper"

class AutomationMailerTest < ActionMailer::TestCase
  def setup
    @organization = create :organization
    requester = create(:user, organization: @organization)
    agent = create(:user, organization: @organization)
    @ticket = create :ticket, :with_desc, subject: "I need help about this plugin.", organization: @organization,
      requester: requester, agent: agent
    rule = rule = create :automation_rule, organization: @organization
    group = create :automation_condition_group, rule: rule
    create :desk_core_condition, conditionable: group, field: "subject", verb: "contains", value: "expect"

    stub_request(:any, /fonts.googleapis.com/)
  end

  def parse_email_body(html)
    Nokogiri::HTML(html).css("body").inner_html.strip
  end

  def test_mail_to_requester
    action = create :automation_action,
      name: "email_to_requester",
      subject: "Our team is already working on the issue.",
      body: "<div>We will fix this ASAP.</div>"

    email = AutomationMailer
      .with(organization_name: "", ticket_id: @ticket.id, receiver_id: @ticket.requester_id)
      .mail_to(action.body.body&.to_html)
      .deliver_now

    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal ["notification.staging@neeto.com"], email.from
    assert_equal "neetoDesk", email.from_address.name
    assert_includes email.to, @ticket.requester.email
    assert_includes email.subject, "Re: #{@ticket.subject}"

    body = parse_email_body(email.html_part.body.raw_source)
    assert_includes body, "<div>We will fix this ASAP.</div>"
    assert_includes body, "TICKETS EMAIL FOOTER CONTENT"
  end

  def test_that_from_and_reply_to_are_taken_from_organizations_configuration
    create :email_configuration, organization: @organization, email: "aa", from_name: "organization_name"

    action = create :automation_action, name: "email_to_requester", body: "Test"

    email = AutomationMailer
      .with(organization_name: "", ticket_id: @ticket.id, receiver_id: @ticket.requester_id)
      .mail_to(action.body&.to_s)
      .deliver_now

    assert_equal ["aa#{@organization.email_domain_suffix}"], email.from
    assert_equal @organization.name, email.from_address.name
    assert_equal ["aa#{@organization.email_domain_suffix}"], email.reply_to
  end

  def test_that_from_and_reply_to_are_taken_from_tickets_configuration
    create :email_configuration, organization: @organization, email: "aa", from_name: "organization_name"
    config_2 = create :email_configuration, organization: @organization, email: "ticket", from_name: "organization_name"
    @ticket.update(email_configuration: config_2)

    action = create :automation_action, name: "email_to_requester", body: "Test"

    email = AutomationMailer
      .with(organization_name: "", ticket_id: @ticket.id, receiver_id: @ticket.requester_id)
      .mail_to(action.body&.to_s)
      .deliver_now

    assert_equal ["ticket#{@organization.email_domain_suffix}"], email.from
    assert_equal @organization.name, email.from_address.name
    assert_equal ["ticket#{@organization.email_domain_suffix}"], email.reply_to
  end

  def test_that_from_name_is_always_organization_name_from_configuration
    create :email_configuration, organization: @organization, email: "aa", from_name: "custom_name", custom_name: "TEST"

    action = create :automation_action, name: "email_to_requester", body: "Test"

    email = AutomationMailer
      .with(organization_name: "", ticket_id: @ticket.id, receiver_id: @ticket.requester_id)
      .mail_to(action.body&.to_s)
      .deliver_now

    assert_equal ["aa#{@organization.email_domain_suffix}"], email.from
    assert_equal @organization.name, email.from_address.name
    assert_equal ["aa#{@organization.email_domain_suffix}"], email.reply_to
  end

  def test_mail_to_agent
    user = create :user, organization: @organization
    action = create :automation_action,
      name: "email_to_agent",
      actionable: user,
      subject: "Our team is already working on the issue.",
      body: "<div>We will fix this ASAP and update you about this.</div>"

    email = AutomationMailer
      .with(organization_name: "", ticket_id: @ticket.id)
      .mail_to(action.body.body&.to_html, action.actionable.email)
      .deliver_now

    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal ["notification.staging@neeto.com"], email.from
    assert_includes email.to, action.actionable.email
    assert_includes email.subject, "Re: #{@ticket.subject}"

    body = parse_email_body(email.html_part.body.raw_source)
    assert_includes body, "<div>We will fix this ASAP and update you about this.</div>"
    assert_includes body, "TICKETS EMAIL FOOTER CONTENT"
  end

  def test_mail_to_agent_bcc_is_added
    setting = @ticket.organization.setting
    setting.update(auto_bcc: true, bcc_email: "test@example.com")

    user = create :user, organization: @organization
    action = create :automation_action,
      name: "email_to_agent",
      actionable: user,
      subject: "Our team is already working on the issue.",
      body: "<div>We will fix this ASAP and update you about this.</div>"

    email = AutomationMailer
      .with(organization_name: "", ticket_id: @ticket.id)
      .mail_to(action.body.body&.to_html, action.actionable.email)
      .deliver_now

    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal ["notification.staging@neeto.com"], email.from
    assert_includes email.to, action.actionable.email
    assert_includes email.subject, "Re: #{@ticket.subject}"
    assert_equal ["bb@test.com", "bb@best.com", "test@example.com"], email.bcc

    body = parse_email_body(email.html_part.body.raw_source)
    assert_includes body, "<div>We will fix this ASAP and update you about this.</div>"
    assert_includes body, "TICKETS EMAIL FOOTER CONTENT"
  end
end
