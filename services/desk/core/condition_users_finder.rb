# frozen_string_literal: true

class Desk::Core::ConditionUsersFinder < Desk::Core::BaseUsersFinder
  def matching_users_for(organization)
    organization.users.where(matching_user_predicate)
  end

  def matching_user_predicate
    return unless valid_verb?

    case field
    when "last_sign_in_at", "created_at", "first_seen_at"
      Desk::Core::UsersFinder::TimeBased.new(field, verb, value).matching_user_predicate
    else
      send("predicate_field_#{verb}")
    end
  end

  def join_table
  end

  private

    def query_field
      users[field]
    end

    def predicate_field_is
      query_field.eq(value)
    end

    def predicate_field_is_not
      query_field.not_eq(value)
    end

    def predicate_field_contains
      query_field.matches("%#{value}%")
    end

    def predicate_field_starts_with
      query_field.matches("#{value}%")
    end

    def predicate_field_ends_with
      query_field.matches("%#{value}")
    end

    def predicate_field_less_than
      query_field.lt(value)
    end

    def predicate_field_greater_than
      query_field.gt(value)
    end

    def predicate_field_any_time
      users[:id].not_eq(nil)
    end
end
