# frozen_string_literal: true

class Desk::Ticket::Comment::CreateService
  attr_reader :ticket, :comment_options, :comment, :skip_notification

  def initialize(ticket, comment_options, skip_notification = false)
    @ticket = ticket
    @comment_options = comment_options
    @skip_notification = skip_notification
  end

  def process
    Comment.transaction do
      update_in_reply_to
      add_comment
    end

    if comment.persisted?
      send_response_to_user!

      if comment.reply?
        send_automated_customer_satisfaction_survey
      end

      instrument_ticket_reply_notification unless skip_notification.present?
      broadcast_data
    end

    comment
  end

  private

    def add_comment
      @comment = ticket.comments.create(comment_options.merge(message_id: Comment.generate_message_id))
    end

    def update_in_reply_to
      unless comment_options.include?(:in_reply_to_id)
        comment_options.merge!(in_reply_to_id: ticket.latest_comment&.message_id)
      end
    end

    def send_response_to_user!
      if comment.reply? && ticket_is_opened_via_twitter_channel?
        ::Desk::TwitterReplyServiceWorker.perform_async(comment.id)
      else
        ::Desk::Ticket::Comment::EmailNotificationsService.new(ticket, comment).process
      end
    end

    def ticket_is_opened_via_email_channel?
      ticket.email?
    end

    def ticket_is_opened_via_twitter_channel?
      ticket.twitter?
    end

    def send_automated_customer_satisfaction_survey
      return unless ticket.organization.customer_satisfaction_surveys.enabled.present?

      Desk::CustomerSatisfactions::Surveys::AutomatedNotificationService.new(ticket).process
    end

    def instrument_ticket_reply_notification
      event = @comment.note? ? "note" : "reply"
      ActiveSupport::Notifications.instrument(
        "ticket.updated.#{event}.added", ticket:,
        performed_by: @comment.authored_by_role)
    end

    def broadcast_data
      TicketChannel.broadcast_new_comment(comment)
    end
end
