# frozen_string_literal: true

module Desk::Core::TicketsFinder
  class TicketFields < Desk::Core::BaseTicketsFinder
    def matching_ticket_predicate
      tickets[:id].in(
        all_ids_predicate.where(
          send("predicate_field_#{verb}")
        )
      )
    end

    private

      def all_ids_predicate
        tickets
          .project(tickets[:id])
          .join(desk_ticket_field_responses).on(
            tickets[:id].eq(desk_ticket_field_responses[:owner_id]).and(
              desk_ticket_field_responses[:ticket_field_id].eq(field)
            )
          )
      end

      def query_field_value
        desk_ticket_field_responses[:value].lower
      end

      def query_field_option
        desk_ticket_field_responses[:ticket_field_option_id]
      end

      # Use this to match value against ID columns
      def value_is_uuid?
        uuid_regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
        uuid_regex.match?(value)
      end

      def predicate_field_is
        predicate = query_field_value.eq(value)
        return predicate unless value_is_uuid?

        predicate.or(
          query_field_option.eq(value)
        )
      end

      def predicate_field_is_not
        predicate = query_field_value.not_eq(value)
        return predicate unless value_is_uuid?

        predicate.or(
          query_field_option.not_eq(value)
        )
      end

      def predicate_field_contains
        query_field_value.matches("%#{value}%")
      end

      def predicate_field_does_not_contain
        query_field_value.does_not_match("%#{value}%")
      end

      def predicate_field_less_than
        cast_field_as_integer(query_field_value).lt(value)
      end

      def predicate_field_greater_than
        cast_field_as_integer(query_field_value).gt(value)
      end

      def predicate_field_contains_any_of
        predicate = query_field_value.matches_any([value])
        return predicate unless value_is_uuid?

        predicate.or(
          query_field_option.matches_any([value])
        )
      end

      def predicate_field_contains_all_of
        predicate = query_field_value.matches_all(value)
        return predicate unless value_is_uuid?

        predicate.or(
          query_field_option.matches_all([value])
        )
      end
  end
end
