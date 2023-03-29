# frozen_string_literal: true

module Desk::Integrations::Twitter
  class TicketHandlerService
    attr_reader :user, :subject, :content, :organization, :in_reply_to_id, :message_id, :attachments,
      :options

    def initialize(
      user, subject, content, organization, in_reply_to_id,
      message_id, attachments, options = {}
    )
      @user = user
      @subject = subject
      @content = content
      @organization = organization
      @in_reply_to_id = in_reply_to_id
      @message_id = message_id
      @options = options.merge(attachments:, status:)
    end

    def run
      add_user_to_organization
      if new_ticket?
        Desk::Ticketing::TicketCreatorService
          .new(user, subject, content, organization, nil, in_reply_to_id, message_id, options)
          .run
      else
        Desk::Ticketing::TicketCommentCreatorService
          .new(parent_comment, user, content, message_id, options)
          .run
      end
    end

    private

      def new_ticket?
        options[:new_ticket]
      end

      def status
        user.blocked? ? Ticket::DEFAULT_STATUSES[:spam] : Ticket::INITIAL_STATUS
      end

      def add_user_to_organization
        if !organization.has_user?(user.email)
          user.assign_organization(organization)
        end
      end

      def parent_comment
        options[:parent_comment]
      end
  end
end
