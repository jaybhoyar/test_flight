# frozen_string_literal: true

class Desk::Core::BaseTicketsFinder
  attr_reader :kind, :field, :verb, :value, :tag_ids

  SUPPORTED_VERB_CONDITIONS = [
    "is", "is_not", "contains", "does_not_contain", "starts_with",
    "ends_with", "contains_any_of", "contains_all_of", "contains_none_of",
    "less_than", "greater_than", "during", "not_during", "any_time"
  ]

  def initialize(kind, field, verb, value, tag_ids = [])
    @kind = kind
    @field = field
    @verb = verb
    @value = sanitize_value(value)
    @tag_ids = tag_ids
  end

  def valid_verb?
    SUPPORTED_VERB_CONDITIONS.include? verb
  end

  [ :tickets, :users, :taggings, :activities, :comments,
    :action_text_rich_texts, :desk_ticket_field_responses, :tags ].each do |method|
    define_method(method) do
      Arel::Table.new(method)
    end
  end

  def survey_responses
    Arel::Table.new(:desk_customer_satisfaction_survey_responses)
  end

  def scale_choices
    Arel::Table.new(:desk_customer_satisfaction_scale_choices)
  end

  def empty_result_predicate
    tickets[:id].eq(nil)
  end

  def all_results_predicate
    tickets[:id].not_eq(nil)
  end

  def requesters_join
    tickets
      .join(users).on(
        tickets[:requester_id].eq(users[:id])
      )
      .join_sources
  end

  def submitters_join
    tickets
      .join(users).on(
        tickets[:submitter_id].eq(users[:id])
      )
      .join_sources
  end

  def agents_join
    tickets
      .join(users).on(
        tickets[:agent_id].eq(users[:id])
      )
      .join_sources
  end

  def tags_join
    tickets.join(taggings).on(
      tickets[:id].eq(taggings[:taggable_id])
      .and(taggings[:taggable_type].eq("Ticket"))
    ).join_sources
  end

  def activities_join
    tickets.join(activities).on(
      tickets[:id].eq(activities[:trackable_id]).and(activities[:trackable_type].eq("Ticket"))
    ).join_sources
  end

  def desk_ticket_fields_join
    tickets.join(desk_ticket_field_responses).on(
      tickets[:id].eq(desk_ticket_field_responses[:owner_id])
        .and(desk_ticket_field_responses[:ticket_field_id].eq(field))
    ).join_sources
  end

  def feedbacks_join
    tickets
      .join(survey_responses).on(
        tickets[:id].eq(survey_responses[:ticket_id])
      )
      .join(scale_choices).on(
        survey_responses[:scale_choice_id].eq(scale_choices[:id])
      )
      .join_sources
  end

  def created_on_day
    @_created_on_day ||= Arel::Nodes::NamedFunction.new(
      "to_char",
      [tickets[:created_at], Arel::Nodes.build_quoted("FMDay")])
  end

  def created_at_time
    @_created_at_time ||= Arel::Nodes::NamedFunction.new("CAST", [tickets[:created_at].as("time")])
  end

  def cast_field_as_integer(field)
    Arel::Nodes::NamedFunction.new("CAST", [field.as("integer")])
  end

  def values_array
    value.split("||")
  end

  def cast_value_as_boolean(val)
    ActiveModel::Type::Boolean.new.cast(val)
  end

  def is_value_boolean?(val)
    val == "true" || val == "false"
  end

  private

    def sanitize_value(value)
      val = value == "Unassigned" ? nil : value == nil ? value&.downcase : value&.to_s.downcase
      is_value_boolean?(val) ? cast_value_as_boolean(val) : val
    end
end
