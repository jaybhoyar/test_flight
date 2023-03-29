# frozen_string_literal: true

class Desk::BusinessHours::DeletionService
  attr_reader :response
  attr_accessor :business_hours, :errors

  def initialize(business_hours)
    @business_hours = business_hours
    @business_hours_count = business_hours.count
    self.errors = []
  end

  def process
    Desk::BusinessHour.transaction do
      business_hours.each do |business_hour|
        business_hour.remove_all_groups!
        business_hour.destroy
        set_errors(business_hour)
      end
    end

    delete_service_response
  end

  def success?
    errors.empty?
  end

  private

    def set_errors(business_hour)
      if business_hour.errors.any?
        errors.push(business_hour.errors.full_messages.to_sentence)
      end
    end

    def delete_service_response
      if errors.empty?
        @response = "#{@business_hours_count == 1 ? "Business Hour has" : "Business Hours have"} been successfully deleted"
      end
    end
end
