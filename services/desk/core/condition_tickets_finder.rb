# frozen_string_literal: true

class Desk::Core::ConditionTicketsFinder < Desk::Core::BaseTicketsFinder
  def matching_tickets_for(organization)
    organization.tickets.joins(join_table).where(matching_ticket_predicate)
  end

  def matching_ticket_predicate
    return unless valid_verb?

    case kind
    when "tags"
      Desk::Core::TicketsFinder::Tags.new(kind, field, verb, value, tag_ids).matching_ticket_predicate
    when "ticket_field"
      Desk::Core::TicketsFinder::TicketFields.new(kind, field, verb, value, tag_ids).matching_ticket_predicate
    when "time_based"
      Desk::Core::TicketsFinder::TimeBased.new(kind, field, verb, value, tag_ids).matching_ticket_predicate
    else
      build_other_field_predicates
    end
  end

  def join_table
    case kind
    when "tags"
      tags_join if verb == "contains_any_of"
    when "time_based"
      activities_join
    else
      case field
      when "requester.email", "company_id"
        requesters_join
      when "submitter_role"
        submitters_join
      when "agent.available_for_desk"
        agents_join
      when "feedback"
        feedbacks_join
      end
    end
  end

  private

    def build_other_field_predicates
      case field
      # any, description, latest
      when /ticket.comments/, "subject_or_description"
        Desk::Core::TicketsFinder::Comments.new(kind, field, verb, value, tag_ids).matching_ticket_predicate
      when "feedback"
        Desk::Core::TicketsFinder::Feedback.new(kind, field, verb, value, tag_ids).matching_ticket_predicate
      when "created_at"
        Desk::Core::TicketsFinder::BusinessHours.new(kind, field, verb, value, tag_ids).matching_ticket_predicate
      else
        send("predicate_field_#{verb}", get_query_field)
      end
    end

    def get_query_field
      case field
      when "requester.email"
        users[:email].lower
      when "company_id"
        users[:company_id]
      when "submitter_role"
        users[:organization_role_id]
      when "agent.available_for_desk"
        users[:available_for_desk]
      when "priority", "agent_id", "created_at", "group_id", "email_configuration_id"
        tickets[field]
      else
        tickets[field].lower
      end
    end

    def predicate_field_is(query_field)
      query_field.eq(value)
    end

    def predicate_field_is_not(query_field)
      query_field.not_eq(value)
    end

    def predicate_field_contains(query_field)
      query_field.matches("%#{value}%")
    end

    def predicate_field_starts_with(query_field)
      query_field.matches("#{value}%")
    end

    def predicate_field_ends_with(query_field)
      query_field.matches("%#{value}")
    end

    def predicate_field_contains_any_of(query_field)
      query_field.matches_any(values_array.map { |val| "%#{val}%" })
    end

    def predicate_field_contains_all_of(query_field)
      query_field.matches_all(values_array.map { |val| "%#{val}%" })
    end

    def predicate_field_contains_none_of(query_field)
      query_field.does_not_match_all(values_array.map { |val| "%#{val}%" })
    end

    def predicate_field_does_not_contain(query_field)
      query_field.does_not_match("%#{value}%")
    end

    def predicate_field_less_than(query_field)
      query_field.lt(value)
    end

    def predicate_field_greater_than(query_field)
      query_field.gt(value)
    end
end
