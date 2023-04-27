# frozen_string_literal: true

require "test_helper"

module Desk::Ticketing
  class OrganizationFinderServiceTest < ActiveSupport::TestCase
    def setup
      @email_configuration = create(:email_configuration)
    end

    def test_run_with_valid_email
      assert_equal @email_configuration.organization,
        OrganizationFinderService.new(@email_configuration.forward_to_email).run
    end

    def test_run_with_invaid_email
      refute OrganizationFinderService.new("invalid@email.com").run
    end
  end
end
