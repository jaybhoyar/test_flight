# frozen_string_literal: true

class Desk::Companies::DeletionService
  attr_reader :response
  attr_accessor :companies, :errors

  def initialize(companies)
    @companies = companies
    @number_of_companies = companies.count
    self.errors = []
  end

  def process
    Company.transaction do
      companies.each do |company|
        company.remove_all_customers!
        company.destroy
        set_errors(company)
      end
    end

    create_service_response
  end

  def success?
    errors.empty?
  end

  private

    def set_errors(company)
      if company.errors.any?
        errors.push(company.errors.full_messages.to_sentence)
      end
    end

    def create_service_response
      if errors.empty?
        @response = "#{@number_of_companies == 1 ? "Company has" : "Companies have"} been successfully deleted."
      end
    end
end
