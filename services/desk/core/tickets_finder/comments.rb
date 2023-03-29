# frozen_string_literal: true

module Desk::Core::TicketsFinder
  class Comments < Desk::Core::BaseTicketsFinder
    def matching_ticket_predicate
      if field === "subject_or_description"
        subject_pred = send("predicate_field_#{verb}", subject)
        description_pred = send("predicate_field_#{verb}", description)

        if verb === "does_not_contain"
          subject_pred.and(description_pred)
        else
          subject_pred.or(description_pred)
        end
      else
        send("predicate_field_#{verb}")
      end
    end

    private

      def subject
        tickets[:subject].lower
      end

      def description
        action_text_rich_texts[:body].lower
      end

      def predicate_field_contains(field = description)
        tickets[:id].in(
          matching_ticket_ids_predicate.where(
            field.matches("%#{value}%")
          )
        )
      end

      def predicate_field_does_not_contain(field = description)
        tickets[:id].not_in(
          matching_ticket_ids_predicate.where(
            field.matches("%#{value}%")
          )
        )
      end

      def predicate_field_contains_any_of(field = description)
        tickets[:id].in(
          matching_ticket_ids_predicate.where(
            field.matches_any(values_array.map { |val| "%#{val}%" })
          )
        )
      end

      def predicate_field_contains_all_of(field = description)
        tickets[:id].in(
          matching_ticket_ids_predicate.where(
            field.matches_all(values_array.map { |val| "%#{val}%" })
          )
        )
      end

      def predicate_field_contains_none_of(field = description)
        tickets[:id].not_in(
          matching_ticket_ids_predicate
            .where(
              field.matches_any(values_array.map { |val| "%#{val}%" })
            )
        )
      end

      # Helpers
      def matching_ticket_ids_predicate
        tickets
          .project(tickets[:id])
          .join(comments).on(coments_join_predicate)
          .join(action_text_rich_texts).on(
            comments[:id].eq(action_text_rich_texts[:record_id]).and(
              action_text_rich_texts[:record_type].eq("Comment")
            )
          )
      end

      def coments_join_predicate
        predicate = comments[:ticket_id].eq(tickets[:id])

        case field
        when "ticket.comments.description"
          predicate.and(
            comments[:comment_type].eq(Comment.comment_types[:description])
          )
        when "ticket.comments.latest"
          predicate.and(
            comments[:latest].eq(true)
          )
        else
          predicate
        end
      end
  end
end
