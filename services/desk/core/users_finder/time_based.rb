# frozen_string_literal: true

module Desk::Core::UsersFinder
  class TimeBased < Desk::Core::BaseUsersFinder
    def matching_user_predicate
      verb_duration_predicate
    end

    private

      def select_date_field
        users[field]
      end

      def verb_duration_predicate
        case verb
        when "is"
          select_date_field.between(offset_time_begin..offset_time_end)
        when "less_than"
          select_date_field.between(offset_time_begin..current_time)
        when "greater_than"
          value.nil? ? select_date_field.not_eq(value) : select_date_field.lt(offset_time_begin)
        end
      end

      def current_time
        Time.current
      end

      def offset_time_begin
        (current_time - value.to_i.days).beginning_of_day
      end

      def offset_time_end
        offset_time_begin.end_of_day
      end
  end
end
