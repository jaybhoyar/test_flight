# frozen_string_literal: true

class Desk::Ticket::Comment::Filter::Base
  attr_reader :rule, :comments, :column, :filter_options

  def initialize(comments, filter_options)
    @rule = filter_options[:rule].underscore
    @column = filter_options[:node].underscore
    @filter_options = filter_options
    @comments = comments
  end

  def search
    comments.where("#{column}": processed_attributes_values)
  end

  private

    def processed_attributes_values
      raise "Implement in child class"
    end
end
