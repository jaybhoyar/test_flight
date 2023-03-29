# frozen_string_literal: true

class Desk::Ticket::Comment::Filter::MultiValueOrSearchService < Desk::Ticket::Comment::Filter::Base
  private

    def attribute_value
      filter_options[:value].split(",")
    end

    def processed_attributes_values
      rule == "empty" ? [nil] : attribute_value
    end
end
