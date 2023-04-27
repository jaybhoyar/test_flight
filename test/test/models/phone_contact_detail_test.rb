# frozen_string_literal: true

require "test_helper"

class PhoneContactDetailTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
  end

  test "create success of phone as a contact detail with valid params" do
    valid_phone = "123456789"
    phone = PhoneContactDetail.new(value: valid_phone, user_id: @user.id)
    assert phone.valid?
  end

  test "create failure of phone as a contact detail with invalid params" do
    invalid_phone = "12abcd3456"
    phone = PhoneContactDetail.new(value: invalid_phone, user_id: @user.id)
    assert_not phone.valid?
  end
end
