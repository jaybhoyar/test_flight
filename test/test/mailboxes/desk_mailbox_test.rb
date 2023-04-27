# frozen_string_literal: true

require "test_helper"

class DeskMailboxTest < ActionMailbox::TestCase
  def setup
    Redis.new.flushdb

    @email_configuration = create(:email_configuration)
    @organization = @email_configuration.organization
    @requester = create :user, organization: @organization
    @ticket = create :ticket, :with_desc, organization: @organization, requester: @requester
    @subject = "Unable to generate invoice"
    @body = "I am not able to generate a new invoice. It says Error 500."

    @agent_role = create :organization_role_agent, organization: @organization
    @admin_role = create :organization_role_admin, organization: @organization
  end

  def teardown
    Redis.new.flushdb
  end

  def test_html_part_email
    subject = "Unable to generate invoice"

    assert_difference "ActionMailbox::InboundEmail.count" do
      to_email = @email_configuration.forward_to_email
      mail = Mail.new do
        to to_email
        from "Mikel Lindsaar <mikel@test.lindsaar.net.au>"
        subject subject

        html_part do
          content_type "text/html; charset=UTF-8"
          body "<h1>I am not able to generate a new invoice. It says Error 500.</h1>"
        end
      end
      receive_inbound_email_from_source(mail.to_s)
    end

    new_ticket = @organization.tickets.where(subject:).first
    assert new_ticket.latest_comment.info.to_s.include? "<h1>I am not able to generate"

    assert_equal "Mikel", new_ticket.requester.first_name
    assert_equal "Lindsaar", new_ticket.requester.last_name
  end

  def test_html_part_email_without_name
    subject = "Unable to generate invoice"

    assert_difference "ActionMailbox::InboundEmail.count" do
      to_email = @email_configuration.forward_to_email
      mail = Mail.new do
        to to_email
        from "<mikel.lindsaar@test.net.au>"
        subject subject

        html_part do
          content_type "text/html; charset=UTF-8"
          body "<h1>I am not able to generate a new invoice. It says Error 500.</h1>"
        end
      end
      receive_inbound_email_from_source(mail.to_s)
    end

    new_ticket = @organization.tickets.where(subject:).first

    assert_equal "Mikel", new_ticket.requester.first_name
    assert_equal "Lindsaar", new_ticket.requester.last_name
  end

  def test_html_part_email_with_empty_subject
    subject = "Unable to generate invoice"

    assert_difference "ActionMailbox::InboundEmail.count" do
      to_email = @email_configuration.forward_to_email
      mail = Mail.new do
        to to_email
        from "Mikel Lindsaar <mikel@test.lindsaar.net.au>"
        subject ""

        html_part do
          content_type "text/html; charset=UTF-8"
          body "<h1>I am not able to generate a new invoice. It says Error 500.</h1>"
        end
      end
      receive_inbound_email_from_source(mail.to_s)
    end

    assert @organization.tickets.exists?(subject: "I am not able to generate a new invoice. It say...")
  end

  def test_that_message_reply_section_is_stripped_off_from_email_before_creating_a_comment
    subject = "Unable to generate invoice"

    body = forward_content

    comment = create :comment, ticket: @ticket

    assert_difference "ActionMailbox::InboundEmail.count" do
      to_email = @email_configuration.forward_to_email
      mail = Mail.new do
        to to_email
        from "Mikel Lindsaar <mikel@test.lindsaar.net.au>"
        subject subject

        html_part do
          content_type "text/html; charset=UTF-8"
          body body
        end
      end
      mail["In-Reply-To"] = comment.message_id
      receive_inbound_email_from_source(mail.to_s)
    end

    description = @ticket.comments.description.first.info.to_s

    assert_not description.include? "messageBodySection"
    assert_not description.include? "messageReplySection"
    assert_not description.include? "gmail_quote"
    assert_not description.include? "ticket-email__footer"
  end

  def test_that_message_reply_section_is_not_stripped_off_from_email_while_creating_a_new_ticket
    subject = "Unable to generate invoice"

    body = forward_content

    assert_difference "ActionMailbox::InboundEmail.count" do
      to_email = @email_configuration.forward_to_email
      mail = Mail.new do
        to to_email
        from "Mikel Lindsaar <mikel@test.lindsaar.net.au>"
        subject subject

        html_part do
          content_type "text/html; charset=UTF-8"
          body body
        end
      end
      receive_inbound_email_from_source(mail.to_s)
    end

    new_ticket = @organization.tickets.where(subject:).first

    info = new_ticket.latest_comment.info.to_s

    assert info.include? "messageBodySection"
    assert info.include? "messageReplySection"
    assert info.include? "gmail_quote"
    assert info.include? "ticket-email__footer"
  end

  def test_that_ticket_is_created
    assert_not @organization.tickets.where(subject: @subject).present?
    assert_difference "ActionMailbox::InboundEmail.count" do
      receive_inbound_email_from_mail \
        to: @email_configuration.forward_to_email,
        from: "morpheus@matrix.com",
        subject: @subject,
        body: @body
    end

    assert_equal 1, @organization.tickets.where(subject: @subject).count

    ticket = @organization.tickets.where(subject: @subject).first

    assert_equal 1, ticket.comments.count

    comment = ticket.comments.first

    assert_equal @body, comment.info.to_plain_text

    assert comment.message_id.present?
    assert_not comment.in_reply_to_id.present?
  end

  def test_that_ticket_is_created_when_subject_and_body_is_nil
    assert_not @organization.tickets.where(subject: @subject).present?
    assert_difference "ActionMailbox::InboundEmail.count" do
      receive_inbound_email_from_mail \
        to: @email_configuration.forward_to_email,
        from: "morpheus@matrix.com",
        subject: "",
        body: ""
    end

    assert @organization.tickets.exists? subject: "[No Content]"
  end

  def test_that_forwarded_ticket_is_created
    assert_not @organization.tickets.where(subject: @subject).present?

    assert_difference "@organization.tickets.count" do
      assert_difference "ActionMailbox::InboundEmail.count" do
        receive_inbound_email_from_mail \
          to: "support@spinkart-company.com",
          from: "morpheus@matrix.com",
          subject: @subject,
          body: @body,
          'X-Forwarded-To': @email_configuration.forward_to_email
      end
    end

    ticket = @organization.tickets.where(subject: @subject).first

    assert_equal 1, ticket.comments.count

    comment = ticket.comments.first

    assert_equal @body, comment.info.to_plain_text

    assert comment.message_id.present?
    assert_not comment.in_reply_to_id.present?
  end

  def test_that_email_is_bounced_with_missing_organization_email
    organization_name = nil
    assert_difference "ActionMailbox::InboundEmail.count" do
      receive_inbound_email_from_mail \
        to: "support-#{organization_name}@neetoticket.net",
        from: "morpheus@matrix.com",
        subject: @subject,
        body: @body
    end
    assert_equal "bounced", ActionMailbox::InboundEmail.first.status
  end

  def test_that_email_is_bounced_with_blocked_user_email
    @requester.deactivate!
    assert_no_difference "::Ticket.count" do
      assert_difference "ActionMailbox::InboundEmail.count" do
        receive_inbound_email_from_mail \
          to: @email_configuration.forward_to_email,
          from: @requester.email,
          subject: @subject,
          body: @body
      end
    end
    assert_equal "bounced", ActionMailbox::InboundEmail.first.status
  end

  def test_that_ticket_is_created_as_spam_by_blocked_customers
    @requester.block!

    assert_difference "::Ticket.count" do
      assert_difference "ActionMailbox::InboundEmail.count" do
        receive_inbound_email_from_mail \
          to: @email_configuration.forward_to_email,
          from: @requester.email,
          subject: @subject,
          body: @body
      end
    end

    ticket = @organization.tickets.where(subject: @subject).first
    assert ticket.spammed?
  end

  def test_that_comment_is_created_when_a_reply_is_received_to_a_ticket
    comment = create :comment, ticket: @ticket

    assert_no_difference "::Ticket.count" do
      assert_difference "@ticket.comments.count", 1 do
        assert_difference "ActionMailbox::InboundEmail.count" do
          receive_inbound_email_from_mail \
            to: @email_configuration.forward_to_email,
            from: "morpheus@matrix.com",
            subject: @subject,
            body: @body,
            'In-Reply-To': comment.message_id
        end
      end
    end

    new_comment = ActionText::RichText.where(name: "info", body: @body, record_type: "Comment").first.record

    assert_equal comment.ticket, new_comment.ticket
    assert_equal "morpheus@matrix.com", new_comment.author.email

    assert new_comment.message_id.present?
    assert new_comment.in_reply_to_id.present?
  end

  def test_that_comment_is_created_when_a_reply_is_received_with_attachments_without_body
    @ticket.comments.description.first.update(created_at: 2.days.ago)
    comment = create :comment, ticket: @ticket, created_at: 1.day.ago

    assert_no_difference "::Ticket.count" do
      assert_difference "@ticket.comments.count", 1 do
        assert_difference "ActionMailbox::InboundEmail.count" do
          mail = Mail.new(
            to: @email_configuration.forward_to_email,
            from: "morpheus@matrix.com",
            subject: @subject,
            body: "Hello world!",
            'In-Reply-To': comment.message_id
          )
          mail.add_file filename: "example.txt", content: StringIO.new("Hello NeetoDesk Mailbox")
          receive_inbound_email_from_source(mail.to_s)
        end
      end
    end

    new_comment = @ticket.comments.order(:created_at).last

    assert_equal comment.ticket, new_comment.ticket
    assert_equal "morpheus@matrix.com", new_comment.author.email

    assert_equal 1, new_comment.attachments.count

    assert new_comment.message_id.present?
    assert new_comment.in_reply_to_id.present?
  end

  def test_that_comment_is_created_with_only_one_attachment
    @ticket.comments.description.first.update(created_at: 2.days.ago)
    comment = create :comment, ticket: @ticket, created_at: 1.day.ago

    file = File.open(Rails.root.join("public", "apple-touch-icon.png"))

    forward_to_email = @email_configuration.forward_to_email
    assert_no_difference "::Ticket.count" do
      assert_difference "@ticket.comments.count", 1 do
        assert_difference "ActionMailbox::InboundEmail.count" do
          mail = Mail.new do
            to forward_to_email
            from "morpheus@matrix.com"
            subject @subject
            body "Hello world!"

            html_part do
              content_type "text/html; charset=UTF-8"
              body "Hello world"
            end
          end
          mail["In-Reply-To"] = comment.message_id
          mail.add_file filename: "example.png", content: file.read
          receive_inbound_email_from_source(mail.to_s)
        end
      end
    end

    new_comment = @ticket.comments.order(:created_at).last

    assert_equal comment.ticket, new_comment.ticket
    assert_equal "morpheus@matrix.com", new_comment.author.email

    assert_equal 1, new_comment.attachments.count

    assert new_comment.message_id.present?
    assert new_comment.in_reply_to_id.present?
  end

  def test_that_comment_is_not_created_when_a_reply_is_empty_and_without_attachments
    comment = create :comment, ticket: @ticket

    assert_no_difference "::Ticket.count" do
      assert_no_difference "@ticket.comments.count", 1 do
        assert_difference "ActionMailbox::InboundEmail.count" do
          receive_inbound_email_from_mail \
            to: @email_configuration.forward_to_email,
            from: "morpheus@matrix.com",
            subject: @subject,
            body: "<div></div>",
            'In-Reply-To': comment.message_id
        end
      end
    end
  end

  def test_that_replying_to_a_note_creates_a_note
    comment = create :comment, :note, ticket: @ticket

    assert_no_difference "::Ticket.count" do
      assert_difference "@ticket.comments.count", 1 do
        assert_difference "ActionMailbox::InboundEmail.count" do
          receive_inbound_email_from_mail \
            to: @email_configuration.forward_to_email,
            from: "morpheus@matrix.com",
            subject: @subject,
            body: @body,
            'In-Reply-To': comment.message_id
        end
      end
    end

    new_comment = ActionText::RichText.where(name: "info", body: @body, record_type: "Comment").first.record

    assert_equal comment.ticket, new_comment.ticket
    assert_equal "morpheus@matrix.com", new_comment.author.email

    assert new_comment.message_id.present?
    assert new_comment.in_reply_to_id.present?
    assert new_comment.note?
  end

  def test_that_reply_by_requester_to_a_note_creates_a_reply
    comment = create :comment, :note, ticket: @ticket

    assert_no_difference "::Ticket.count" do
      assert_difference "@ticket.comments.count", 1 do
        assert_difference "ActionMailbox::InboundEmail.count" do
          receive_inbound_email_from_mail \
            to: @email_configuration.forward_to_email,
            from: @requester.email,
            subject: @subject,
            body: @body,
            'In-Reply-To': comment.message_id
        end
      end
    end

    new_comment = ActionText::RichText.where(name: "info", body: @body, record_type: "Comment").first.record
    assert new_comment.reply?
  end

  def test_that_followers_are_notified_when_a_reply_is_created_via_email
    ethan = create :user, organization: @organization, first_name: "Ethan"
    jason = create :user, organization: @organization, first_name: "Jason"

    create :desk_ticket_follower, ticket: @ticket, user: jason
    @ticket.update(agent: ethan)

    comment_1 = create :comment, :reply, ticket: @ticket, author: ethan

    stub_request(:any, /fonts.googleapis.com/)

    assert_emails 2 do
      receive_inbound_email_from_mail \
        to: @email_configuration.forward_to_email,
        from: jason.email,
        subject: @subject,
        body: @body,
        'In-Reply-To': comment_1.message_id
    end
  end

  def test_that_admin_and_agent_followers_are_notified_when_a_note_is_created_via_email
    ethan = create :user, role: @admin_role, organization: @organization, first_name: "Ethan"
    jason = create :user, role: @agent_role, organization: @organization, first_name: "Jason"

    create :desk_ticket_follower, ticket: @ticket, user: jason
    @ticket.update(agent: ethan)

    comment_1 = create :comment, :note, ticket: @ticket, author: ethan

    stub_request(:any, /fonts.googleapis.com/)

    assert_emails 1 do
      receive_inbound_email_from_mail \
        to: @email_configuration.forward_to_email,
        from: jason.email,
        subject: @subject,
        body: @body,
        'In-Reply-To': comment_1.message_id
    end
  end

  def test_receiving_attachments_with_email
    subject = "Unable to generate invoice"
    body = "I am not able to generate a new invoice. It says Error 500."

    assert_not @organization.tickets.where(subject:).present?

    assert_difference "ActionMailbox::InboundEmail.count" do
      mail = Mail.new(
        to: @email_configuration.forward_to_email,
        from: "morpheus@matrix.com",
        subject:,
        body:
      )
      mail.add_file filename: "example.txt", content: StringIO.new("Hello NeetoDesk Mailbox")
      receive_inbound_email_from_source(mail.to_s)
    end

    new_ticket = @organization.tickets.where(subject:).first
    new_comment = ActionText::RichText.where(name: "info", body:, record_type: "Comment").first.record

    assert new_ticket.present?
    assert new_comment.present?

    assert_equal 1, new_comment.attachments.count
    assert_equal "text/plain", new_comment.attachments.last.content_type
    assert_equal "example.txt", new_comment.attachments.last.filename.to_s
  end

  def test_that_ticket_is_created_with_no_content_text_when_body_is_not_provided
    assert_not @organization.tickets.where(subject: @subject).present?

    assert_difference ["ActionMailbox::InboundEmail.count", "::Ticket.count"] do
      receive_inbound_email_from_mail \
        to: @email_configuration.forward_to_email,
        from: "morpheus@matrix.com",
        subject: @subject,
        body: nil
    end

    assert_equal 1, @organization.tickets.where(subject: @subject).count

    ticket = @organization.tickets.where(subject: @subject).first

    assert_equal 1, ticket.comments.count

    comment = ticket.comments.first

    assert_equal "", comment.info.to_plain_text

    assert comment.message_id.present?
    assert_not comment.in_reply_to_id.present?
  end

  def test_that_email_is_ignored_when_received_from_blacklisted_emails
    DeskMailbox.any_instance.stubs(:blacklisted_emails).returns("cap@avengers.com")

    assert_no_difference "::Ticket.count" do
      receive_inbound_email_from_mail \
        to: @email_configuration.forward_to_email,
        from: "cap@avengers.com",
        subject: @subject,
        body: nil
    end
  end

  def test_that_email_is_ignored_when_received_from_mailbox_domain
    DeskMailbox.any_instance.stubs(:blacklisted_emails).returns("cap@avengers.com")

    assert_no_difference "::Ticket.count" do
      receive_inbound_email_from_mail \
        to: @email_configuration.forward_to_email,
        from: @email_configuration.forward_to_email,
        subject: @subject,
        body: nil
    end
  end

  def test_that_multiple_emails_from_same_customer_are_throttled_and_some_are_skipped
    DeskMailbox.any_instance.stubs(:perform_throttling?).returns(true)

    assert_difference "::Ticket.count", 10 do
      110.times.each do
        receive_inbound_email_from_mail \
          to: @email_configuration.forward_to_email,
          from: @requester.email,
          subject: "Spamming emails!",
          body: "I am just sending spam emails!"
      end
    end

    # 110 original jobs
    #
    # 10 executed immediately
    # 90 re-scheduled
    # 100 skipped
    assert_enqueued_jobs 200 # 110 + 90
  end

  def test_that_multiple_emails_to_the_organization_are_throttled
    DeskMailbox.any_instance.stubs(:perform_throttling?).returns(true)

    assert_difference "::Ticket.count", 100 do
      110.times.each do
        receive_inbound_email_from_mail \
          to: @email_configuration.forward_to_email,
          from: Faker::Internet.email,
          subject: "Spamming emails!",
          body: "I am just sending spam emails!"
      end
    end

    # 110 original jobs
    #
    # 100 executed immediately
    # 10 re-scheduled
    assert_enqueued_jobs 120 # 110 + 10
  end

  private

    def forward_content
      <<~TEXT
        <!DOCTYPE html>
        <html>
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
            <style>
            /* Email styles need to be inline */
            </style>
          </head>
          <body>
            <p></p>
            <div class="trix-content">
              <div name="messageBodySection">
                <div>Awesome thanks!</div>
              </div>
              <div name="messageReplySection">
                On 11 Aug 2020, 8:00 PM +0530, John Doe
              </div>
              <div class="gmail_quote">
                On 11 Aug 2020, 8:00 PM +0530, John Doe
              </div>
            </div>
            <div class="ticket-email__footer">
              -
              <br>You can reply to this email directly.
            </div>
          </body>
        </html>
        TEXT
    end
end
