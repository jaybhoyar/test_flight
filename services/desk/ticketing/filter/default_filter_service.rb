# frozen_string_literal: true

module Desk::Ticketing
  module Filter
    class DefaultFilterService
      attr_reader :organization, :default_filter_by, :tickets, :user, :model_names
      attr_reader :customer_id

      def initialize(organization, default_filter_by, user, customer_id)
        @default_filter_by = default_filter_by
        @organization = organization
        @user = user
        @customer_id = customer_id
        @tickets = default_filtered_tickets
      end

      def process
        tickets
      end

      private

        def default_filtered_tickets
          _default_filtered_tickets.preload(:requester).includes(includes_list)
        end

        def _default_filtered_tickets
          case default_filter_by
          when "all"
            organization_tickets.open
          when "assigned_to_me"
            organization_tickets.open.where(agent: user)
          when "unassigned"
            organization_tickets.open.unassigned
          when "assigned"
            organization_tickets.open.assigned
          when "unresolved"
            organization_tickets.open.unresolved
          when "resolved"
            organization_tickets.open.resolved
          when "closed", "spam", "trash"
            organization_tickets.of_status Ticket::DEFAULT_STATUSES[default_filter_by.to_sym]
          else
            organization_tickets.open
          end
        end

        def includes_list
          [:tags, :group]
        end

        def organization_tickets
          @organization_tickets ||= begin
            tickets = organization.tickets
            tickets = tickets.where(requester_id: customer_id, requester_type: "User") if customer_id
            tickets
          end
        end
    end
  end
end
