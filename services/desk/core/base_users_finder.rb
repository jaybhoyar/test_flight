# frozen_string_literal: true

class Desk::Core::BaseUsersFinder
  attr_reader :field, :verb, :value

  SUPPORTED_VERB_CONDITIONS = [
    "is", "is_not", "contains", "less_than", "greater_than", "any_time", "starts_with", "ends_with"
  ]

  def initialize(field, verb, value)
    @field = field
    @verb = verb
    @value = value&.downcase
  end

  def valid_verb?
    SUPPORTED_VERB_CONDITIONS.include? verb
  end

  [:users, :organizations].each do |method|
    define_method(method) do
      Arel::Table.new(method)
    end
  end
end
