# frozen_string_literal: true

class Desk::Automation::Rules::CloneService
  attr_reader :rule
  attr_accessor :errors, :status, :response

  SUFFIX_VERB = " - CLONED - "

  def initialize(rule)
    @rule = rule
  end

  def build_rule
    dup_rule = rule.dup
    dup_rule.condition_groups = duplicate_condition_groups
    dup_rule.actions = duplicate_actions
    dup_rule.name = build_new_name

    dup_rule
  end

  private

    def duplicate_condition_groups
      rule.condition_groups.map do |condition_group|
        new_group = condition_group.dup
        new_group.conditions = duplicate_conditions(condition_group)
        new_group
      end
    end

    def duplicate_conditions(condition_group)
      condition_group.conditions.map do |condition|
        new_condition = condition.dup
        new_condition.tag_ids = condition.tag_ids
        new_condition
      end
    end

    def duplicate_actions
      rule.actions.map do |action|
        new_action = action.dup
        new_action.tag_ids = action.tag_ids
        new_action.body = action.body
        new_action
      end
    end

    def build_new_name
      "#{original_rule_name}#{name_suffix}"
    end

    def original_rule_name
      return rule.name unless name_includes_suffix?

      rule.name.split(SUFFIX_VERB).first
    end

    def name_suffix
      "#{SUFFIX_VERB}#{Time.current.to_i}"
    end

    def name_includes_suffix?
      rule.name.include?(SUFFIX_VERB)
    end
end
