# frozen_string_literal: true

module Desk::Ticketing
  module Filter
    class KeywordSearchService < Base
      STARTS_WITH_REGEX = /\A#/

      def search
        if rule == "contains"
          tickets.joins(comments: :action_text_rich_text)
            .where("tickets.subject ILIKE :query OR
                         tickets.number::text ILIKE :query OR
                         action_text_rich_texts.body ILIKE :query",
              query: "%#{processed_attributes_values}%")
            .distinct
        else
          tickets.includes(model_names).where("#{column}": processed_attributes_values)
        end
      end

      private

        def processed_attributes_values
          filter_options[:value]&.gsub(STARTS_WITH_REGEX, "")
        end
    end
  end
end
