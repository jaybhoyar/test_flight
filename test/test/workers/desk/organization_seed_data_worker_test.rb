# frozen_string_literal: true

require "test_helper"

module Desk
  class OrganizationSeedDataWorkerTest < ActiveSupport::TestCase
    require "sidekiq/testing"

    def setup
      Sidekiq::Testing.inline!
    end

    def test_that_default_organization_data_is_created
      organization = create :organization

      Desk::OrganizationSeedDataWorker.new.perform(organization.id)

      organization.reload

      assert_equal 1, organization.business_hours.count
      assert_equal 5, organization.business_hours.first.schedules.count
      assert_equal 1, organization.business_hours.first.holidays.count
      assert_equal 1, organization.customer_satisfaction_surveys.count
      assert_equal 9, organization.rules.count
      assert_equal 4, organization.tags.count
      assert_equal 3, organization.desk_macros.count
      assert_equal 6, organization.tickets.count
    end
  end
end
