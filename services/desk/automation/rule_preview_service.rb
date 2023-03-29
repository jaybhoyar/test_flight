# frozen_string_literal: true

class Desk::Automation::RulePreviewService
  attr_reader :organization, :options, :automation_rule

  def initialize(organization, options)
    @organization = organization
    @options = options
    @automation_rule = build_rule
  end

  def matching_tickets
    automation_rule.matching_tickets
  end

  def matching_users
    automation_rule.matching_users
  end

  def valid_conditions?
    automation_rule.condition_groups.each do |group|
      group.conditions.each do |condition|
        return false unless condition.valid?
      end
    end
    true
  end

  def error_messages
    automation_rule.validate
    automation_rule.errors.full_messages.filter do |message|
      message.starts_with?("Condition groups")
    end.map do |message|
      message.remove("Condition groups conditions").squish.capitalize
    end
  end

  private

    def build_rule
      organization.rules.new(options)
    end
end
