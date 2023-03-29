# frozen_string_literal: true

module Desk::Ticketing
  class UpdateTicketService
    attr_accessor :ticket
    attr_reader :options, :organization, :options, :user

    def initialize(organization, ticket, user, options)
      @ticket = ticket
      @options = options
      @organization = organization
      @user = user
    end

    def process
      Ticket.transaction do
        ticket.update(ticket_options)

        if ticket.valid?
          update_description
          update_ticket_fields
          add_ticket_tags
        end
      end

      send_automated_customer_satisfaction_survey
      instrument_ticket_updated_notifications
    end

    private

      def ticket_options
        ticket_attributes = options.slice(
          :subject, :agent_id, :group_id, :status, :priority, :resolution_due_date,
          :category, :requester, :comments_attributes, :spam, :trash
        )

        if user.present?
          if ticket.requester_id == user.id
            ticket_attributes[:last_requester_updated_at] = Time.current
          elsif ticket.agent_id == user.id
            ticket_attributes[:last_agent_updated_at] = Time.current
          end
        end

        ticket_attributes
      end

      def add_ticket_tags
        if tag_present?
          DetailsTagsService.new(organization, ticket, options).process
        elsif tag_key_present?
          DetailsTagsService.new(organization, ticket, options).clear
        end
      end

      def tag_present?
        options[:tags].present?
      end

      def tag_key_present?
        (options.keys & ["tags", :tag]).present?
      end

      def update_description
        description_comment = ticket.comments.description.first

        if options[:description]
          description_comment.update(info: options[:description])
        end

        if options[:deleted_attachments]
          description_comment.attachments.where(id: options[:deleted_attachments]).destroy_all
        end

        attachments = options.dig(:options, :attachments)
        if attachments
          attachments.each do |attachment|
            description_comment.attachments.attach(attachment)
          end
        end
      end

      def update_ticket_fields
        return if options[:ticket_field_responses_attributes].blank?

        UpdateTicketFieldsService.new(organization, ticket, options[:ticket_field_responses_attributes]).process
      end

      def send_automated_customer_satisfaction_survey
        return unless ticket.saved_change_to_status?

        Desk::CustomerSatisfactions::Surveys::AutomatedNotificationService.new(ticket).process
      end

      def instrument_ticket_updated_notifications
        events = [].tap do |e|
          e << "priority" if ticket.saved_change_to_priority?
          e << "category" if ticket.saved_change_to_category?
          e << "group" if ticket.saved_change_to_group_id?
          e << "agent" if ticket.saved_change_to_agent_id?

          # Instrument status events
          if ticket.saved_change_to_status?
            e << (ticket.trashed? ? "moved to trash" : ticket.spammed? ? "marked as spam" : "status")
          end
        end

        performed_by = ticket.requester == user ? "requester" : "agent"

        # Instrument ticket update notification
        ActiveSupport::Notifications.instrument("ticket.updated", ticket:, performed_by:)

        # Instrument tickets field update notifications
        events.each do |event|
          ActiveSupport::Notifications.instrument("ticket.updated.#{event}", ticket:, performed_by:)
        end
      end
  end
end
