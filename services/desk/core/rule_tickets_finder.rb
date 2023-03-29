# frozen_string_literal: true

class Desk::Core::RuleTicketsFinder
  attr_reader :query, :rule, :accumulative_query

  def initialize(rule)
    @rule = rule
  end

  def base_query
    rule.organization.tickets
  end

  def matching_tickets
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

    base_query.joins(join_tables).where(accumulative_query).distinct
  end

  def rule_matching_tickets
    join_tables = []
    queries = nil

    sorted_condition_groups.each do |group|
      conditions_queries = nil

      group.conditions.each do |condition|
        join_table, predicate = run_condition_query_builder(condition)
        join_tables << join_table

        conditions_queries = if conditions_queries.nil?
          predicate
        elsif group.condition_join_and_operator?
          conditions_queries.and(predicate)
        else
          conditions_queries.or(predicate)
        end
      end

      queries = if queries.nil?
        conditions_queries
      elsif group.and_operator?
        queries.and(conditions_queries)
      else
        queries.or(conditions_queries)
      end
    end

    base_query.joins(join_tables).where(queries).distinct
  end

  private

    def run_condition_query_builder(condition)
      builder = Desk::Core::ConditionTicketsFinder.new(
        condition.kind, condition.field, condition.verb,
        condition.value, condition.tag_ids)
      [builder.join_table, builder.matching_ticket_predicate]
    end

    def sorted_conditions
      # Skipping sorting while previewing conditions
      return rule.conditions unless rule.id

      rule.conditions
    end

    def sorted_condition_groups
      # Skipping sorting while previewing conditions
      return rule.condition_groups unless rule.id

      rule.condition_groups
    end
end
