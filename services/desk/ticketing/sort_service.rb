# frozen_string_literal: true

module Desk::Ticketing
  class SortService
    attr_reader :tickets, :options

    def initialize(tickets, options)
      @tickets = tickets
      @options = options
    end

    def sorted_tickets
      sorted_tickets = tickets.left_joins(:latest_comment)
      return sorted_tickets unless options

      if options[:sort_by].present?
        sort_by = options[:sort_by]
        sort_argument = "#{sort_by[:column]} #{sort_by[:direction]}"
      end
      sorted_tickets.order(sort_argument || "comments.created_at desc")
    end
  end
end
