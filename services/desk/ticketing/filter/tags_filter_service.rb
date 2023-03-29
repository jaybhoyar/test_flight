# frozen_string_literal: true

module Desk::Ticketing
  module Filter
    class TagsFilterService < Base
      def search
        tickets.where(predicate)
      end

      private

        def tag_ids
          filter_options[:value].split(",")
        end

        def predicate
          tickets_table[:id].in(all_ids_predicate)
        end

        def all_ids_predicate
          tickets_table
            .project(tickets_table[:id])
            .join(ticket_tags_table).on(
              tickets_table[:id].eq(ticket_tags_table[:taggable_id])
              .and(ticket_tags_table[:taggable_type].eq("Ticket"))
            )
            .where(
              ticket_tags_table[:tag_id].in(tag_ids)
            )
            .group(tickets_table[:id])
            .having(
              ticket_tags_table[:tag_id].count.eq(tag_ids.count)
            )
        end

        def tickets_table
          Arel::Table.new(:tickets)
        end

        def ticket_tags_table
          Arel::Table.new(:taggings)
        end
    end
  end
end
