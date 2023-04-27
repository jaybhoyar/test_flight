# frozen_string_literal: true

require "test_helper"

class CompanyDomainTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @company = create :company, organization: @organization
  end

  def test_that_company_domain_is_valid
    company_domain = build :company_domain, company: @company

    assert company_domain.valid?
  end
end
