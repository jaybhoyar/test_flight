# frozen_string_literal: true

module Desk::Ticketing
  class TicketHandlerService
    attr_reader :support_email

    def initialize(support_email)
      @support_email = support_email
    end

    def run
      if new_ticket?
        TicketCreatorService.new(*ticket_arguments, attachments:, status:).run
      elsif !empty_reply?
        TicketCommentCreatorService.new(*comment_arguments, attachments:, comment_type:).run
      end
    end

    private

      def ticket_arguments
        [
          support_email.from_user,
          subject,
          support_email.original_content,
          support_email.organization,
          support_email.to_email_config,
          support_email.in_reply_to_id,
          support_email.message_id,
        ]
      end

      def comment_arguments
        [
          parent_comment,
          support_email.from_user,
          description,
          support_email.message_id,
        ]
      end

      def subject
        support_email.subject.presence || Nokogiri::HTML(description).text&.truncate(50)
      end

      def status
        support_email.from_user.blocked? ? Ticket::DEFAULT_STATUSES[:spam] : Ticket::INITIAL_STATUS
      end

      def description
        @_description ||= content_blank? ? "[No Content]" : support_email.sanitized_content
      end

      def empty_reply?
        attachments.blank? && content_blank?
      end

      def attachments
        support_email.attachments
      end

      def content_blank?
        @_content_blank ||= Comment.new(info: support_email.sanitized_content).info.blank?
      end

      def new_ticket?
        support_email.new_ticket?
      end

      def is_requester?
        if new_ticket?
          true
        else
          parent_comment.ticket.requester == support_email.from_user
        end
      end

      def parent_comment
        support_email.parent_comment
      end

      def comment_type
        if is_requester?
          "reply"
        else
          parent_comment.comment_type === "description" ? "reply" : parent_comment.comment_type
        end
      end
  end
end
