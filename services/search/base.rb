# frozen_string_literal: true

module Search
  class Base
    attr_reader :organization, :value

    def initialize(organization, value)
      @organization = organization
      @value = value
    end

    # scope and predicate to be defined in the sub classes
    def search
      scope.where(predicate)
    end
  end
end
