# frozen_string_literal: true

module Desk::Core::TicketsFinder
  class Tags < Desk::Core::BaseTicketsFinder
    def matching_ticket_predicate
      send("predicate_field_#{verb}")
    end

    private

      def query_field
        taggings[:tag_id]
      end

      def predicate_field_contains_any_of
        query_field.in(tag_ids)
      end

      def predicate_field_contains_all_of
        tickets[:id].in(all_ids_predicate)
      end

      def predicate_field_contains_none_of
        tickets[:id].in(no_tag_ids_predicate)
          .or(
            tickets[:id].in(no_match_ids_predicate)
          )
      end

      def all_ids_predicate
        ids_predicate
          .group(tickets[:id])
          .having(
            taggings[:tag_id].count.eq(tag_ids.count)
          )
      end

      def ids_predicate
        tickets
          .project(tickets[:id])
          .join(taggings).on(
            tickets[:id].eq(taggings[:taggable_id])
            .and(taggings[:taggable_type].eq("Ticket"))
          ).where(
            taggings[:tag_id].in(tag_ids)
          )
      end

      def no_tag_ids_predicate
        tickets
          .project(tickets[:id])
          .join(
            Arel.sql(
              "LEFT OUTER JOIN taggings ON taggings.taggable_id = tickets.id AND taggings.taggable_type = 'Ticket'"
            )
          ).where(
            taggings[:id].eq(nil)
          )
      end

      def no_match_ids_predicate
        tickets
          .project(tickets[:id])
          .where(
            tickets[:id].not_in(ids_predicate)
          )
      end
  end
end
