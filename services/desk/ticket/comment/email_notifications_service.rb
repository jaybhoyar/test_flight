# frozen_string_literal: true

class Desk::Ticket::Comment::EmailNotificationsService
  attr_reader :ticket, :comment

  def initialize(ticket, comment)
    @ticket = ticket
    @comment = comment
  end

  def process
    return if email_from.nil?

    body = comment.info.body&.to_html

    followers_list.find_each do |follower|
      cc = []
      bcc = []

      if follower.requester? && comment.forward_emails.present?
        cc = comment.forward_emails.cc.pluck(:email)
        bcc = comment.forward_emails.bcc.pluck(:email)
      end

      CommentMailer.with(
        organization_name: "",
        ticket_id: ticket.id,
        receiver_id: follower.user_id,
        sender_id: comment.author_id,
        comment_id: comment.id
      ).created_email(
        subject:,
        body:,
        in_reply_to_id:,
        reference_message_ids:,
        cc:,
        bcc:
      ).deliver_later
    end
  end

  private

    def followers_list
      followers = comment.note? ? ticket.ticket_followers_without_requester : ticket.ticket_followers
      followers.where.not(user_id: comment.author_id)
    end

    def subject
      @_subject ||= if comment.forward?
        I18n.t("mailer.subject.ticket.forward", subject: ticket.subject)
      else
        I18n.t("mailer.subject.ticket.reply", subject: ticket.subject)
      end
    end

    def email_from
      @_email_from ||= begin
        email_configuration.from(agent: comment.author) if email_configuration
      end
    end

    def in_reply_to_id
      @_in_reply_to_id ||= parent_comment.message_id
    end

    def reference_message_ids
      @_reference_message_ids ||= ticket.comments.pluck(:message_id) - [nil, "", in_reply_to_id]
    end

    def parent_comment
      ticket.ordered_comments.where.not(id: comment.id).last
    end

    def email_configuration
      if ticket.email_configuration
        ticket.email_configuration
      else
        EmailConfiguration.get_latest_for_organization(ticket.organization).first
      end
    end
end
