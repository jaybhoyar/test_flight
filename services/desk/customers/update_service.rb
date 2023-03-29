# frozen_string_literal: true

module Desk::Customers
  class UpdateService
    attr_reader :organization, :customer, :options, :response
    attr_accessor :errors, :status

    def initialize(organization, customer, options = {})
      @organization = organization
      @customer = customer
      @options = options.merge(role: nil)
    end

    def process
      sanitize_parameters_and_update_customer
    end

    private

      def sanitize_parameters_and_update_customer
        customer_details = options.except(:email_contact_details_attributes)
        secondary_emails_details = {}

        if options[:customer_detail_attributes].present? && options[:customer_detail_attributes][:tags].present?
          customer_details[:customer_detail_attributes]&.merge!(
            {
              tag_ids: customer_details[:customer_detail_attributes].delete(:tags).pluck(:id)
            })
        end

        if options[:email_contact_details_attributes].present?
          primary_email_details = primary_email_contact_detail
          secondary_emails_list = filter_secondary_emails(
            primary_email_details.present?
          )
        end
        update_customer(customer_details, primary_email_details, secondary_emails_list)
      end

      def update_customer(customer_details, primary_email_details, secondary_emails_list)
        ActiveRecord::Base.transaction do
          if customer_details[:status] == "unblock"
            @customer.unblock!
          elsif customer_details[:status] == "block"
            @customer.block!
          end

          @customer.update!(customer_details.except(:status))
          @customer.update!(primary_email_details) if primary_email_details.present?

          secondary_emails_list&.each do |email|
            @customer.update!({ email_contact_details_attributes: [email] })
          end

          @status = :ok
          @response = json_response
          true
        rescue ActiveRecord::RecordInvalid => invalid
          set_errors_and_status(invalid.record.errors.full_messages, :unprocessable_entity)
          false
        end
      end

      def primary_email_contact_detail
        primary_email = options[:email_contact_details_attributes].detect do |email|
          ActiveModel::Type::Boolean.new.cast(email[:primary])
        end

        if primary_email.present?
          { email_contact_details_attributes: [primary_email.except(:_destroy)] }
        else
          {}
        end
      end

      def filter_secondary_emails(primary_email_provided)
        options[:email_contact_details_attributes].filter do |email|
          (!ActiveModel::Type::Boolean.new.cast(email[:primary])) && (
            primary_email_provided ? true : email[:id] != primary_email_contact.id
          )
        end
      end

      def primary_email_contact
        @_primary_email_contact ||= @customer.email_contact_details.find_by(value: @customer.email)
      end

      def set_errors_and_status(message, status)
        @errors = message
        @status = status
      end

      def json_response
        status = options.dig(:status)

        if status
          { notice: "#{@customer.name}'s account has been #{status}ed successfully." }
        else
          { notice: "#{@customer.name}'s details have been updated successfully." }
        end
      end
  end
end
