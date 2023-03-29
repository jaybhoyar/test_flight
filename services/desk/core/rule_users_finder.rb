# frozen_string_literal: true

class Desk::Core::RuleUsersFinder
  attr_reader :query, :rule, :accumulative_query

  def initialize(rule)
    @rule = rule
  end

  def base_query
    rule.organization.users.only_active
  end

  def matching_users
    join_tables = []
    accumulative_query = nil

    sorted_conditions.each do |condition|
      join_table, predicate = run_condition_query_builder(condition)
      join_tables << join_table

      if accumulative_query.nil?
        accumulative_query = predicate
        next
      end

      accumulative_query = if condition.and_operator?
        accumulative_query.and(predicate)
      else
        accumulative_query.or(predicate)
      end
    end

    base_query.joins(join_tables).where(accumulative_query)
      .distinct
  end

  private

    def run_condition_query_builder(condition)
      builder = Desk::Core::ConditionUsersFinder.new(condition.field, condition.verb, condition.value)
      [builder.join_table, builder.matching_user_predicate]
    end

    def sorted_conditions
      # Skipping sorting while previewing conditions
      return rule.conditions unless rule.id

      rule.conditions
    end
end
