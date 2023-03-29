# frozen_string_literal: true

module Desk::Ticketing
  class TicketCreatorService
    attr_reader :submitter, :requester, :subject, :content, :organization, :email_config,
      :in_reply_to_id, :message_id, :options, :ticket

    def initialize(submitter, subject, content, organization, email_config, in_reply_to_id, message_id, options = {})
      @organization = organization
      @subject = subject
      @content = content
      @email_config = email_config
      @in_reply_to_id = in_reply_to_id
      @message_id = message_id
      @options = options
      @requester = get_requester(submitter)
      @submitter = submitter || requester
    end

    def run
      @ticket = organization.tickets.build(ticket_params)

      begin
        Ticket.transaction do
          ticket.save!
          update_ticket_fields
          create_status_change_record
        end
      rescue ActiveRecord::RecordInvalid => ex
        # Send exception to honeybadger in the case of email channel only.
        # We can further investigate the failure by using the message_id
        # to find the ActionMailbox::InboundEmail record. The entire email
        # is stored as an attachment and can be be retrieved within 30 days.
        Honeybadger.notify(ex, context: { message_id: }) if message_id.present?
      else
        instrument_ticket_created_notification(ticket)
        broadcast_new_ticket(ticket)
      end

      ticket
    end

    private

      def ticket_params
        {
          requester:,
          submitter:,
          subject:,
          organization:,
          group_id: options[:group_id],
          agent_id: options[:agent_id],
          channel: options[:channel] || "email",
          status: ticket_status,
          priority: options[:priority] || Ticket::InitialPriority,
          category: options[:category] || Ticket::DefaultCategory,
          email_configuration: email_config,
          comments_attributes: [comment_params],
          resolution_due_date:
        }
      end

      def ticket_status
        options[:status] || Ticket::INITIAL_STATUS
      end

      def comment_params
        {
          info: content,
          author: requester,
          in_reply_to_id:,
          message_id: message_id ? message_id : Comment.generate_message_id,
          channel_mode: options[:channel_mode],
          latest: true,
          comment_type: "description",
          attachments: options[:attachments] || []
        }
      end

      def resolution_due_date
        Time.zone.today + Ticket::ResolutionDueDateFirstResponse
      end

      def get_user(customer_email)
        Desk::Customers::FetchOrCreateService.new(organization, customer_email, customer_name).process
      end

      def instrument_ticket_created_notification(ticket)
        performed_by = ticket.requester == submitter ? "requester" : "agent"
        ActiveSupport::Notifications.instrument("ticket.created", ticket:, performed_by:)
      end

      def update_ticket_fields
        if options[:ticket_field_responses_attributes].present?
          ticket.update!(ticket_field_responses_attributes: options[:ticket_field_responses_attributes])
        end
      end

      def user
        @_user ||= User.current
      end

      def get_requester(submitter)
        options[:customer_email].presence ? get_user(options[:customer_email]) : submitter
      end

      def customer_name
        return options[:customer_name] if options[:customer_name].present?

        if options[:ticket_field_responses_attributes] && customer_name_ticket_field
          ticket_field_response = options[:ticket_field_responses_attributes].find { |response|
            response[:ticket_field_id] == customer_name_ticket_field.id
          }
          ticket_field_response.present? && ticket_field_response[:value]
        end
      end

      def customer_name_ticket_field
        organization.ticket_fields.find_by(agent_label: "Customer Name")
      end

      def broadcast_new_ticket(ticket)
        TicketsChannel.broadcast_new_ticket(ticket)
      end

      def create_status_change_record
        ticket.status_changes.create! status: "new"
      end
  end
end
