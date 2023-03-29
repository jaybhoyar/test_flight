# frozen_string_literal: true

module Desk::Ticketing
  class DetailsTagsService
    attr_accessor :organization, :ticket, :options, :raw_tags

    def initialize(organization, ticket, options)
      @organization = organization
      @ticket = ticket
      @options = options
      @raw_tags = options[:tags]&.map { |tag| tag.merge(name: tag[:name].strip) }
    end

    def process
      update_tags
    end

    def clear
      delete_tags
    end

    private

      def delete_tags
        @ticket.update_tags([])
      end

      def organization_tags
        @_organization_tags ||= organization.ticket_tags
      end

      def update_tags
        not_existing_tags = raw_tags.filter { |tag| tag[:id].blank? }
        add_new_tags(not_existing_tags)
        update_ticket_tags
      end

      def update_ticket_tags
        tags = organization_tags.where(name: raw_tags.map { |tag| tag[:name] })
        ticket.update_tags(tags)
      end

      def add_new_tags(not_existing_tags)
        organization_tags.create(not_existing_tags)
      end
  end
end
