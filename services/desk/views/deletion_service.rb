# frozen_string_literal: true

class Desk::Views::DeletionService
  attr_reader :response
  attr_accessor :views, :errors

  def initialize(views)
    @views = views
    @number_of_views = views.count
    @errors = []
  end

  def process
    View.transaction do
      views.each do |view|
        view.destroy
        set_errors(view)
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
        @response = "#{@number_of_views == 1 ? "View has" : "Views have"} been successfully deleted"
      end
    end
end
