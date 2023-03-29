# frozen_string_literal: true

module Desk::Ticketing
  class ForwardTicketService
    attr_accessor :ticket, :forward_text, :forward_emails, :author, :comment, :attachments

    def initialize(ticket, forward_text, forward_emails, attachments, author)
      @ticket = ticket
      @forward_text = forward_text
      @forward_emails = forward_emails
      @author = author
      @attachments = attachments
    end

    def process
      Comment.transaction do
        @comment = create_forward_comment if ticket.valid?
      end

      send_email if comment.valid?

      comment
    end

    private

      def prepare_attachments
        attachments&.map do |attachment|
          if attachment.is_a? Integer
            ActiveStorage::Attachment.find(attachment).blob
          else
            attachment
          end
        end
      end

      def send_email
        CommentMailer
          .with(organization_name: "", ticket_id: @ticket.id, comment_id: comment.id)
          .forward_email
          .deliver_later
      end

      def create_forward_comment
        TicketCommentCreatorService.new(parent_comment, author, forward_text, message_id, options).run
      end

      def parent_comment
        @_parent_comment ||= ticket.latest_comment || ticket.comments.order(updated_at: :desc).first
      end

      def message_id
        parent_comment.message_id
      end

      def options
        {
          comment_type: Comment.comment_types[:forward],
          forward_emails:,
          attachments: prepare_attachments
        }
      end
  end
end
