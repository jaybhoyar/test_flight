# frozen_string_literal: true

class Desk::Automation::Rules::SearchService
  attr_accessor :organization, :term

  def initialize(organization, term)
    @organization = organization
    @term = term&.downcase
  end

  def search
    organization.rules
      .joins(conditions_join, actions_join)
      .includes(:recent_executions, :recently_modified_tickets)
      .where(predicate_for_term)
      .uniq
  end

  private

    def predicate_for_term
      return no_results if term.blank?

      rule_predicates
        .or(condition_predicates)
        .or(action_predicates)
    end

    def rules
      @_rules = Arel::Table.new(:desk_core_rules)
    end

    def conditions
      @_conditions = Arel::Table.new(:desk_core_conditions)
    end

    def condition_groups
      @_condition_groups = Arel::Table.new(:desk_core_condition_groups)
    end

    def actions
      @_actions = Arel::Table.new(:desk_core_actions)
    end

    def conditions_join
      rules
        .join(condition_groups).on(
          rules[:id].eq(condition_groups[:rule_id])
        )
        .join(conditions).on(
          condition_groups[:id].eq(conditions[:conditionable_id])
        )
        .join_sources
    end

    def actions_join
      rules
        .join(actions).on(
          actions[:rule_id].eq(rules[:id])
        )
        .join_sources
    end

    def rule_predicates
      rules[:name].lower.matches("%#{term}%")
        .or(rules[:description].lower.matches("%#{term}%"))
    end

    def condition_predicates
      conditions[:field].lower.matches("%#{term}%")
        .or(conditions[:value].lower.matches("%#{term}%"))
    end

    def action_predicates
      actions[:subject].lower.matches("%#{term}%")
        .or(actions[:value].lower.matches("%#{term}%"))
    end

    def no_results
      rules[:id].eq(nil)
    end
end
