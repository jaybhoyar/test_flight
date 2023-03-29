# frozen_string_literal: true

module Desk::Ticketing
  class TicketCommentCreatorService
    attr_reader :parent_comment, :contact, :content, :message_id, :options

    def initialize(parent_comment, contact, content, message_id, options = {})
      @parent_comment = parent_comment
      @contact = contact
      @content = content
      @message_id = message_id
      @options = options
    end

    def run
      comment = add_comment!
      add_attachments(comment)
      notify_ticket_followers(comment)
      instrument_ticket_reply_notification(comment)
      broadcast_data(comment)

      comment
    end

    def add_comment!
      if options[:comment_type] == "Forward"
        Comment.where(ticket_id: parent_comment.ticket_id).create! comment_params
      else
        Comment.where(ticket_id: parent_comment.ticket_id).create! comment_params.except(:forward_emails_attributes)
      end
    end

    def add_attachments(comment)
      if options[:attachments]
        options[:attachments].each do |attachment|
          comment.attachments.attach(attachment)
        end
      end
    end

    def notify_ticket_followers(comment)
      unless comment.forward?
        Desk::Ticket::Comment::EmailNotificationsService.new(parent_comment.ticket, comment).process
      end
    end

    def instrument_ticket_reply_notification(comment)
      event = comment.note? ? "note" : "reply"
      ActiveSupport::Notifications.instrument(
        "ticket.updated.#{event}.added", ticket: parent_comment.ticket,
        performed_by: comment.authored_by_role)
    end

    def broadcast_data(comment)
      TicketChannel.broadcast_new_comment(comment)
    end

    private

      def comment_params
        comment_params = {
          info: content,
          author: contact,
          in_reply_to_id: parent_comment.message_id,
          message_id:,
          comment_type: options[:comment_type].presence || Comment.comment_types[:reply],
          channel_mode: options[:channel_mode],
          forward_emails_attributes: options[:forward_emails]
        }
      end
  end
end
