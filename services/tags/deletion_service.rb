# frozen_string_literal: true

class Tags::DeletionService
  attr_reader :response
  attr_accessor :tags, :errors

  def initialize(tags)
    @tags = tags
    self.errors = []
  end

  def process
    Tag.transaction do
      tags.each do |tag|
        tag.destroy
        set_errors(tag)
      end
    end

    create_service_response
  end

  def success?
    errors.empty?
  end

  private

    def set_errors(record)
      if record.errors.any?
        errors << record.errors.full_messages.to_sentence
      end
    end

    def create_service_response
      if errors.empty?
        if tags.one?
          @response = "Tag has been successfully deleted."
        else
          @response = "Tags have been successfully deleted."
        end
      end
    end
end
