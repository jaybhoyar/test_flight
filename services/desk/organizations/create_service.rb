# frozen_string_literal: true

module Desk::Organizations
  class CreateService
    include SSOHelpers
    attr_reader :organization_params, :status, :response
    attr_accessor :organization

    def initialize(organization_params, time_zone = nil)
      @organization_params = organization_params
      @response = {}
      @status = :accepted
    end

    def process
      ActiveRecord::Base.transaction do
        create_organization

        set_success_response
      rescue ActiveRecord::RecordInvalid => exception
        set_error_response(exception.record)
      end

      organization
    end

    def success?
      status == :ok
    end

    private

      def create_organization
        @organization = ::Organization.new(organization_params)
        organization.save!
      end

      def set_success_response
        @response = { notice: I18n.t("resource.save", resource_name: "Organization") }
        @status = :ok
      end

      def set_error_response(invalid_record)
        @response = { error: invalid_record.error_sentence }
        @status = :unprocessable_entity
      end
  end
end
