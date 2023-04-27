# frozen_string_literal: true

require "test_helper"

class Desk::Customers::FilterServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
    @user = create(:user_with_agent_role, organization: @organization)
    @customer = create(:user, organization: @organization, role: nil)
  end

  def test_index_filters_with_company
    company = create(:company, name: "TinyBinary", organization: @organization)
    create(:user, organization: @organization, company_id: company.id, role: nil)

    params = { customer: { page_size: 15, page_index: 1, filters: { company_ids: [ company.id ] } } }

    filtered_customers = customers_filter_service(@organization.customers, params)
    assert_equal 1, filtered_customers.total_count
  end

  def test_index_for_pagination
    create(:user, organization: @organization, role: nil)
    create(:user, organization: @organization, role: nil)
    create(:user, organization: @organization, role: nil)
    create(:user, organization: @organization, role: nil)
    create(:user, organization: @organization, role: nil)

    params = { customer: { page_size: 5, page_index: 1 } }

    filtered_customers = customers_filter_service(@organization.customers, params)
    assert_equal 6, filtered_customers.total_count
  end

  def test_index_filters_with_status
    create(:user, organization: @organization, blocked_at: DateTime.current, role: nil)

    params = { customer: { page_size: 15, page_index: 1, filters: { status: "active" } } }

    filtered_customers = customers_filter_service(@organization.customers, params)
    assert_equal 1, filtered_customers.total_count
  end

  private

    def customers_filter_service(customers, params)
      Desk::Customers::FilterService.new(customers, params).process
    end
end
