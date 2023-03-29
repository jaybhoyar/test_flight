# frozen_string_literal: true

class Desk::Outbound::RulePreviewService
  attr_reader :organization, :options, :rule

  def initialize(organization, options)
    @organization = organization
    @options = options
    @rule = build_rule
  end

  def matching_users
    rule.matching_users
  end

  def valid_conditions?
    rule.conditions.each do |condition|
      return false unless condition.valid?
    end
    true
  end

  def error_messages
    rule.validate
    rule.errors.full_messages.filter do |message|
      message.starts_with?("Conditions ")
    end
  end

  private

    def build_rule
      rule = ::Outbound::Rule.new(options)
      rule.organization = organization

      rule
    end
end
