# frozen_string_literal: true

module Desk::Customers
  class DeletionService
    attr_reader :response
    attr_accessor :customers, :errors

    def initialize(customers)
      @customers = customers
      @errors = []
    end

    def process
      begin
        ::User.transaction do
          customers.each do |customer|
            customer.destroy
            set_errors(customer)
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
        if record.errors.any?
          errors.push(record.errors.full_messages.to_sentence)
        end
      end

      def create_service_response
        if errors.empty?
          singular_or_plural_subject = customers.length > 1 ? "Customers have" : "Customer has"
          @response = "#{singular_or_plural_subject} been successfully removed."
        end
      end
  end
end
