# frozen_string_literal: true

require "test_helper"

class Desk::Customers::CompanyFinderServiceTest < ActiveSupport::TestCase
  def test_that_company_with_company_domain_that_matches_customer_email_is_returned
    company = create :company, name: "BigBinary"
    create :company_domain, name: "bigbinary.com", company: company

    customer_email = "Matt@bigbinary.com"

    customer_company = Desk::Customers::CompanyFinderService.new(company.organization, customer_email).process

    assert_equal customer_company.id, company.id
  end
end
