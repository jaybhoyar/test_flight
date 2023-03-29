# frozen_string_literal: true

module Desk::Core::TicketsFinder
  class Feedback < Desk::Core::BaseTicketsFinder
    def matching_ticket_predicate
      if value == "any"
        all_results_predicate
      else
        query_field.eq(value)
      end
    end

    private

      def query_field
        scale_choices[:slug]
      end
  end
end
