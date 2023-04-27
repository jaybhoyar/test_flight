# frozen_string_literal: true

require "test_helper"

class Placeholders::OrganizationCarrierTest < ActiveSupport::TestCase
  def test_that_all_keys_are_present
    supported_variables = [
      "id", "name", "subdomain", "tags"
    ]

    organization = create :organization
    create :ticket_tag, organization: organization
    create :ticket_tag, organization: organization

    placeholder = Placeholders::OrganizationCarrier.new(organization)
    assert_equal supported_variables, placeholder.build.keys
  end
end
