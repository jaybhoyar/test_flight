# frozen_string_literal: true

module Desk::Core::TicketsFinder
  class BusinessHours < Desk::Core::BaseTicketsFinder
    attr_reader :business_hour

    def matching_ticket_predicate
      return all_results_predicate if verb == "any_time"

      @business_hour = get_business_hour
      return empty_result_predicate unless business_hour

      predicates = get_schedule_predicates

      predicates.reduce do |clause, condition|
        clause.or(condition)
      end
    end

    private

      def get_schedule_predicates
        business_hour.schedules.active.map do |schedule|
          from = schedule.from.strftime("%H:%M:%S")
          to = schedule.to.strftime("%H:%M:%S")

          business_hours_predicate(schedule.day, from, to)
        end
      end

      def business_hours_predicate(day, from, to)
        if verb == "during"
          created_on_day.eq(day).and(
            created_at_time.between(from..to)
          )
        else
          created_on_day.in(not_scheduled_days).or(
            created_on_day.eq(day).and(
              created_at_time.not_between(from..to)
            )
          )
        end
      end

      def not_scheduled_days
        @_not_scheduled_days ||= begin
          days = business_hour.schedules.active.pluck(:day)
          ::Desk::BusinessHours::Schedule::DAYS_NAMES - days
        end
      end

      def get_business_hour
        ::Desk::BusinessHour.find_by(id: value)
      end
  end
end
