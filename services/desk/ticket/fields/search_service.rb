# frozen_string_literal: true

class Desk::Ticket::Fields::SearchService
  attr_reader :organization, :options

  def initialize(organization, options)
    @organization = organization
    @options = options || {}
  end

  def process
    ticket_fields = organization.ticket_fields.includes(:ticket_field_options, :ticket_field_regex)
    ticket_fields = ticket_fields.search_with_state(options[:state])

    if !options[:search_term].nil?
      ticket_fields = ticket_fields.where("agent_label ILIKE :search_term", search_term: "%#{options[:search_term]}%")
    end

    ticket_fields
  end
end
