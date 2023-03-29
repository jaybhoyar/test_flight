# frozen_string_literal: true

module Desk::Customers
  class CreatorService
    attr_reader :organization, :options, :user, :response
    attr_accessor :errors, :status

    def initialize(organization, user, options = {})
      @user = user
      @organization = organization
      @options = options.merge!(role: "customer")
    end

    def process
      if primary_email.nil?
        set_errors_and_status("Primary email is required", unprocessable_entity)
      elsif organization.has_user?(primary_email)
        set_errors_and_status("Email #{primary_email} already exists.", unprocessable_entity)
      else
        create_customer
      end
    end

    private

      def create_customer
        ActiveRecord::Base.transaction do
          @customer = @organization.users.create!(customer_attrs)
          @status = :ok
          @response = json_response
        rescue ActiveRecord::RecordInvalid => invalid
          set_errors_and_status(invalid.record.errors.full_messages, unprocessable_entity)
        end

        @customer
      end

      def customer_attrs
        first_name = options[:first_name].presence || primary_email.split("@").first

        {
          skip_assign_role: true,
          email: primary_email,
          password: SecureRandom.alphanumeric(100),
          skip_password_validation: true,
          first_name:
        }.merge(options_with_valid_secondary_emails)
      end

      def matching_company
        @_matching_company ||= Desk::Customers::CompanyFinderService
          .new(organization, primary_email)
          .process
      end

      def options_with_valid_secondary_emails
        emails_except_primary = options[:email_contact_details_attributes].select do |email|
          (!ActiveModel::Type::Boolean.new.cast(email[:primary])) && (
            email[:value] =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i && email[:value] != primary_email
          )
        end

        {
          last_name: options[:last_name],
          company_id: options[:company_id] || matching_company&.id,
          customer_detail_attributes: options[:customer_detail_attributes],
          email_contact_details_attributes: emails_except_primary.uniq { |email| email[:value] }
        }.merge!(non_empty_contact_details_attributes)
      end

      def non_empty_contact_details_attributes
        non_empty_contact_details = {}
        if options[:phone_contact_details_attributes].present? &&
          options[:phone_contact_details_attributes].first[:value].present?
          non_empty_contact_details.merge!(phone_contact_details_attributes: options[:phone_contact_details_attributes])
        end
        if options[:link_contact_details_attributes].present? &&
          options[:link_contact_details_attributes].first[:value].present?
          non_empty_contact_details.merge!(link_contact_details_attributes: options[:link_contact_details_attributes])
        end
        non_empty_contact_details
      end

      def primary_email
        @_primary_email_contact ||= begin
          primary_email_contact = options[:email_contact_details_attributes].select do |email|
            email[:primary] == "true" || email[:primary] == true
          end
          primary_email_contact.first && primary_email_contact.first[:value]
        end
      end

      def set_errors_and_status(message, status)
        @errors = message
        @status = status
      end

      def unprocessable_entity
        :unprocessable_entity
      end

      def json_response
        { notice: "Successfully added \'#{@customer.name}\' as a new customer." }
      end
  end
end
