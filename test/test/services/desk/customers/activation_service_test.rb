# frozen_string_literal: true

require "test_helper"

class Desk::Customers::ActivationServiceTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @organization = @user.organization

    @customer_one = create(:user, organization: @organization, role: nil)
    @customer_two = create(:user, organization: @organization, role: nil)
  end

  def test_deactivate_customers_success
    customer_service = Desk::Customers::ActivationService.new(customers).process

    assert_equal "Customers have been successfully blocked.", customer_service
    assert @customer_one.reload.blocked?
    assert @customer_two.reload.blocked?
  end

  def test_activate_single_customer
    @customer_one.deactivate!
    customer_service = Desk::Customers::ActivationService.new([@customer_one], "unblock").process

    assert_equal "#{@customer_one.first_name}'s account has been successfully unblocked.", customer_service
    assert_not @customer_one.reload.blocked?
  end

  private

    def customers
      @organization.users.where(role: nil)
    end
end
