# frozen_string_literal: true

class Desk::Views::RulePreviewService
  attr_reader :organization, :options, :view_rule

  def initialize(organization, options)
    @organization = organization
    @options = options
    @view_rule = build_view_rule
  end

  def matching_tickets
    view_rule.matching_tickets
  end

  def matching_users
    view_rule.matching_users
  end

  def valid_conditions?
    view_rule.conditions.each do |condition|
      return false unless condition.valid?
    end
    true
  end

  def error_messages
    view_rule.validate
    view_rule.errors.full_messages.filter do |message|
      message.starts_with?("Conditions ")
    end
  end

  private

    def build_view_rule
      organization.view_rules.new(options)
    end
end
