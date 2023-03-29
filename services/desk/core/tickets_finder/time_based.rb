# frozen_string_literal: true

module Desk::Core::TicketsFinder
  class TimeBased < Desk::Core::BaseTicketsFinder
    def matching_ticket_predicate
      case status_value
      when "created", "last_requester_updated_at", "assigned_at", "last_assigned_at"
        verb_duration_predicate
      when "updated_at_by_agent_or_requester"
        verb_duration_predicate(tickets[:last_requester_updated_at])
          .or(verb_duration_predicate(tickets[:last_agent_updated_at]))
      else
        ticket_status_predicate.and(verb_duration_predicate)
      end
    end

    private

      def date_field
        case status_value
        when "new", "created"
          tickets[:created_at]
        when "assigned_at", "last_assigned_at", "last_requester_updated_at"
          tickets[status_value]
        else
          activities[:created_at]
        end
      end

      def ticket_status_predicate
        predicate = tickets[:status].eq(Ticket::DEFAULT_STATUSES[status_value.to_sym])
        return predicate if status_value == "new"

        predicate.and(activities_action_predicate)
      end

      def verb_duration_predicate(field_name = nil)
        query_field = field_name || date_field
        case verb
        when "is"
          end_time = offset_time_begin
          start_time = end_time - 1.hours

          query_field.between(start_time..end_time)
        when "less_than"
          query_field.between(offset_time_begin..current_time)
        when "greater_than"
          query_field.lt(offset_time_begin)
        end
      end

      def activities_action_predicate
        activities[:action].lower.matches("% to #{pretty_status_value}%")
      end

      def status_value
        @_status_value ||= field.split("status.hours.").last.downcase
      end

      def pretty_status_value
        status_value.titleize.downcase
      end

      def current_time
        Time.current
      end

      def offset_time_begin
        current_time - value.to_i.hours
      end
  end
end
