# frozen_string_literal: true

class Desk::CustomerSatisfactions::Surveys::DeletionService
  attr_reader :response
  attr_accessor :surveys, :errors

  def initialize(surveys)
    @surveys = surveys
    @errors = []
  end

  def process
    begin
      Desk::CustomerSatisfaction::Survey.transaction do
        surveys.each do |survey|
          unless survey.destroy
            set_errors(survey)
          end
        end
      end

      create_service_response

    rescue ActiveRecord::RecordInvalid => invalid
      set_errors(invalid.record)
      false
    end
  end

  def success?
    errors.empty?
  end

  private

    def set_errors(record)
      errors.push(record.errors.full_messages.to_sentence)
    end

    def survey_ids
      @_survey_ids ||= surveys.pluck(:id)
    end

    def create_service_response
      if errors.empty?
        @response = "#{survey_ids.count === 1 ? "Survey has" : "Surveys have"} been successfully deleted."
      end
    end
end
