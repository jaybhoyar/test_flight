# frozen_string_literal: true

# Assumes that support emails are of the format support-spinkart@neetoticket.com
# Later if we change to organization specific domains or sub-domains, we will
# need to make changes only in this class.

module Desk::Ticketing
  class OrganizationFinderService
    attr_reader :email

    def initialize(email)
      @email = email
    end

    def run
      if (email_configuration = EmailConfiguration.find_by(forward_to_email: email))
        email_configuration.organization
      end
    end
  end
end
