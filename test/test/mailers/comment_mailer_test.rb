# frozen_string_literal: true

require "test_helper"

class CommentMailerTest < ActionMailer::TestCase
  def setup
    stub_request(:any, /fonts.googleapis.com/)
  end

  def test_mail_delivered_when_agent_reply
    ethan = create :user, first_name: "Ethan", last_name: "Hunt"
    ticket = create :ticket_with_email_config, :with_desc, organization: ethan.organization

    comment = create :comment, ticket: ticket, author: ethan
    email = CommentMailer
      .with(
        organization_name: "",
        ticket_id: ticket.id,
        receiver_id: ticket.requester_id,
        sender_id: comment.author_id,
        comment_id: comment.id
      )
      .created_email(
        subject: "Re: #{ticket.subject}",
        body: comment.info.to_s,
        in_reply_to_id: ticket.comments.description.first.message_id,
        reference_message_ids: []
      )
      .deliver

    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email.html_part.body.raw_source, "TICKETS EMAIL FOOTER CONTENT"
  end

  def test_mail_delivered_when_agent_reply_with_bcc_setting
    ethan = create :user, first_name: "Ethan", last_name: "Hunt"
    setting = ethan.organization.setting
    setting.update(auto_bcc: true, bcc_email: "test@example.com")

    ticket = create :ticket_with_email_config, :with_desc, organization: ethan.organization

    comment = create :comment, ticket: ticket, author: ethan
    email = CommentMailer
      .with(
        organization_name: "",
        ticket_id: ticket.id,
        receiver_id: ticket.requester_id,
        sender_id: comment.author_id,
        comment_id: comment.id
      )
      .created_email(
        subject: "Re: #{ticket.subject}",
        body: comment.info.to_s,
        in_reply_to_id: ticket.comments.description.first.message_id,
        reference_message_ids: []
      )
      .deliver

    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal ["bb@test.com", "bb@best.com", "test@example.com"], email.bcc
    assert_includes email.html_part.body.raw_source, "TICKETS EMAIL FOOTER CONTENT"
  end

  def test_mail_delivered_when_agent_forwards_ticket
    ethan = create :user, first_name: "Ethan", last_name: "Hunt"

    ticket = create(:ticket_with_email_config, :with_desc, requester: create(:user))
    comment = create :comment, ticket: ticket, author: ethan
    create :forward_email, delivery_type: "to", comment: comment
    create :forward_email, delivery_type: "cc", comment: comment
    create :forward_email, delivery_type: "bcc", comment: comment

    email = CommentMailer
      .with(organization_name: "", ticket_id: ticket.id, comment_id: comment.id)
      .forward_email
      .deliver

    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal ticket.email_configuration.forward_to_email, email.from.first
    assert_equal comment.author.name, email.from_address.name
    assert_equal comment.forward_emails.to.pluck(:email), email.to
    assert_equal comment.forward_emails.cc.pluck(:email), email.cc

    bccs = ["bb@test.com", "bb@best.com"]
    bccs += comment.forward_emails.bcc.pluck(:email)
    assert_equal bccs, email.bcc

    assert_includes email.html_part.body.raw_source, "Another Comment"
    assert_includes email.html_part.body.raw_source, "TICKETS EMAIL FOOTER CONTENT"
  end

  def test_mail_bcc_from_setting_is_attached_when_forwarded
    ethan = create :user, first_name: "Ethan", last_name: "Hunt"

    ticket = create(:ticket_with_email_config, :with_desc, requester: create(:user))
    setting = ticket.organization.setting
    setting.update(auto_bcc: true, bcc_email: "test@example.com")

    comment = create :comment, ticket: ticket, author: ethan
    create :forward_email, delivery_type: "to", comment: comment
    create :forward_email, delivery_type: "cc", comment: comment
    create :forward_email, delivery_type: "bcc", comment: comment

    email = CommentMailer
      .with(organization_name: "", ticket_id: ticket.id, comment_id: comment.id)
      .forward_email
      .deliver

    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal ticket.email_configuration.forward_to_email, email.from.first
    assert_equal comment.author.name, email.from_address.name
    assert_equal comment.forward_emails.to.pluck(:email), email.to
    assert_equal comment.forward_emails.cc.pluck(:email), email.cc

    bccs = ["bb@test.com", "bb@best.com", "test@example.com"]
    bccs += comment.forward_emails.bcc.pluck(:email)
    assert_equal bccs, email.bcc

    assert_includes email.html_part.body.raw_source, "Another Comment"
    assert_includes email.html_part.body.raw_source, "TICKETS EMAIL FOOTER CONTENT"
  end

  def test_mail_delivered_when_have_attactment
    ethan = create :user, first_name: "Ethan", last_name: "Hunt"
    ticket = create :ticket_with_email_config, :with_desc, organization: ethan.organization

    comment = create :comment, :with_attachments, ticket: ticket, author: ethan

    email = CommentMailer
      .with(
        organization_name: "",
        ticket_id: ticket.id,
        receiver_id: ticket.requester_id,
        sender_id: comment.author_id,
        comment_id: comment.id
      )
      .created_email(
        subject: "Re: #{ticket.subject}",
        body: comment.info.to_s,
        in_reply_to_id: ticket.comments.description.first.message_id,
        reference_message_ids: []
      )
      .deliver
    assert_not_empty email.attachments
  end
end
