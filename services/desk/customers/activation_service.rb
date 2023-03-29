# frozen_string_literal: true

class Desk::Customers::ActivationService
  attr_accessor :customers, :errors, :response, :status

  def initialize(customers, status = "block")
    @customers = customers
    @status = status
    @errors = []
  end

  def process
    customers.each do |customer|
      saved = if status == "unblock"
        customer.unblock!
      else
        customer.block!
      end

      set_errors(customer) unless saved
    end

    create_service_response
  end

  def success?
    errors.empty?
  end

  private

    def set_errors(customer)
      errors.push(customer.errors.full_messages.to_sentence)
    end

    def create_service_response
      if errors.empty?
        @response = "#{customers.length == 1 ? "#{customers.first.first_name}'s account has" : "Customers have"} been successfully #{status}ed."
      end
    end
end
