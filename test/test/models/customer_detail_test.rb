# frozen_string_literal: true

require "test_helper"

class CustomerDetailTest < ActiveSupport::TestCase
  def setup
    @customer_detail = create(:customer_detail)
  end

  test "valid customer detail" do
    assert @customer_detail.valid?
  end

  test "invalid customer detail" do
    customer_detail = CustomerDetail.new
    assert_not customer_detail.valid?
    assert_includes customer_detail.errors.full_messages, "User must exist"
  end
end
