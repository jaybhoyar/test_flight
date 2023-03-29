# frozen_string_literal: true

class Desk::Ticket::Comment::Filter::FilterService
  attr_reader :organization, :options, :comments

  def initialize(organization, options)
    @options = options
    @organization = organization
    @tickets = all_tickets_for_organization
    @comments = []
  end

  def process
    process_comments_filters
    comments
  end

  def search_service_class_name_for_filter(filter_name)
    case filter_name
    when "author_id", "author_type", "comment_type"
      Desk::Ticket::Comment::Filter::MultiValueOrSearchService
    end
  end

  private

    def process_comments_filters
      @tickets.each do |ticket|
        filtered_comments = ticket.comments
        options[:filter_by].each do |index, filter|
          filter_name = filter[:node]
          filtered_comments = search_service_class_name_for_filter(filter_name).new(filtered_comments, filter).search
          filtered_comments = [] && break if filtered_comments.count == 0
        end
        @comments = comments.concat(filtered_comments)
      end
    end

    def all_tickets_for_organization
      @organization.tickets
    end
end
