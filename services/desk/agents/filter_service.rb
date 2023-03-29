# frozen_string_literal: true

class Desk::Agents::FilterService
  include UserQueryHelper

  attr_reader :agents, :options

  def initialize(agents, options)
    @agents = agents
    @options = options
  end

  def process
    @agents = agents.order(full_name.asc.nulls_last)
    if options.present?
      @agents = @agents.where(predicate)
    end

    agents
  end

  private

    def predicate
      full_name.matches(search_value)
        .or(
          users[:email].lower.matches(search_value)
        )
    end

    def search_value
      @_search_value ||= "%#{options.dig(:filters, :search_string)}%"
    end
end
