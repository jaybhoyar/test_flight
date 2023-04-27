# frozen_string_literal: true

require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  def test_remove_all_users
    company = create(:company)
    user = create(:user, role: nil, company:)

    assert_equal 1, company.customers.count
    company.remove_all_customers!
    assert_equal 0, company.reload.customers.count
  end
end
