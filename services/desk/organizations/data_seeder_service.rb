# frozen_string_literal: true

module Desk::Organizations
  class DataSeederService
    attr_reader :organization

    def initialize(organization)
      @organization = organization
    end

    def process
      seed_organization_roles
      seed_default_mailbox

      seed_tags
      seed_business_hour
      seed_tickets
      seed_ticket_fields
      seed_automation_rules # Depends on Business Hours i.e. `seed_business_hour`
      seed_canned_responses
      seed_customer_satisfaction_survey
    end

    private

      def seed_organization_roles
        Desk::Organizations::Seeder::Roles.new(organization).process
      end

      def seed_default_mailbox
        organization.email_configurations.create(email: "support", from_name: "organization_name")
      end

      def seed_business_hour
        business_hour = organization.business_hours.first_or_create! \
          name: Desk::BusinessHour::DEFAULT,
          description: Desk::BusinessHour::DEFAULT

        # Default holidays
        business_hour.holidays.first_or_create!(name: "New Year", date: Date.current.beginning_of_year)

        ::Desk::BusinessHours::CreationService.new.find_and_create_schedules(business_hour.id)
      end

      def seed_tags
        ["refund", "feedback", "sales", "feature-request"].each do |tag_name|
          organization.tags.create(name: tag_name)
        end
      end

      def seed_customer_satisfaction_survey
        Desk::Organizations::Seeder::CustomerSatisfactionSurveys.new(organization).process!
      end

      def seed_canned_responses
        Desk::Organizations::Seeder::CannedResponses.new(organization).process!
      end

      def seed_automation_rules
        Desk::Organizations::Seeder::AutomationRules.new(organization).process!
      end

      def seed_tickets
        Desk::Organizations::Seeder::Tickets.new(organization).process!
      end

      def seed_ticket_fields
        Desk::Organizations::Seeder::TicketFields.new(organization).process!
      end
  end
end
