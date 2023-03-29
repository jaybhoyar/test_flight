# frozen_string_literal: true

class Desk::Tags::MergeService
  attr_reader :options, :organization, :primary, :secondry
  attr_accessor :errors

  def initialize(organization, options)
    @errors = []
    @organization = organization
    @primary = find_tag("primary", options[:primary_id])
    @secondry = find_tag("secondry", options[:secondry_id])
  end

  def merge
    return false if @errors.present?

    ActiveRecord::Base.transaction do
      update_ids
      delete_secondry_tag
    end
  end

  private

    def delete_secondry_tag
      secondry.destroy
    end

    def update_ids
      secondry.tickets.includes(:tags).each do |ticket|
        unless ticket.tags.include?(@primary)
          ticket.tags << @primary
        end
        ticket.tags.delete(secondry)
      end
    end

    def find_tag(element, id)
      tag = @organization.ticket_tags.find_by(id:)
      return tag if tag.present?

      @errors << "Unable to find #{element} tag with id: #{id}."
    end
end
