# frozen_string_literal: true

module Desk::Ticketing
  module Filter
    class DateFilterService < Base
      private

        VALID_HOURS_OR_DAYS_VALUES = ["24.hours.ago", "25.hours.ago", "30.days.ago", "60.days.ago", "90.days.ago",
"180.days.ago"]

        def attribute_value
          filter_options[:value]
        end

        def processed_attributes_values
          case attribute_value
          when "today"
            Time.zone.now.beginning_of_day..Time.zone.now.end_of_day
          when "yesterday"
            yesterday = Time.zone.now.beginning_of_day - 1.day
            yesterday..yesterday.end_of_day
          when "month"
            from = Time.current.beginning_of_month
            to = from.end_of_month
            from..to
          when "week"
            from = Time.current.beginning_of_week
            to = from.end_of_week
            from..to
          when *VALID_HOURS_OR_DAYS_VALUES
            process_attributes_with_hours_or_days
          else
            process_custom_attributes
          end
        end

        def process_attributes_with_hours_or_days
          if attribute_value.split(".").include?("days")
            no_of_days = attribute_value.split(".")[0].to_i
            from = no_of_days.days.ago.beginning_of_day
            to = Time.zone.now.beginning_of_day
            from..to
          else
            no_of_hours = attribute_value.split(".")[0].to_i
            from = no_of_hours.hours.ago
            to = Time.zone.now
            from..to
          end
        end

        def process_custom_attributes
          from = attribute_value.split(",")[0].to_date.beginning_of_day
          to = attribute_value.split(",")[1].to_date.end_of_day
          from..to
        end
    end
  end
end
