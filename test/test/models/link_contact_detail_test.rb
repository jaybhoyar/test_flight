# frozen_string_literal: true

require "test_helper"

class LinkContactDetailTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
  end

  test "create success of link as a contact detail with valid params" do
    valid_link = "https://dribbble.com/ethan_hunt"
    link = LinkContactDetail.new(value: valid_link, user_id: @user.id)
    assert link.valid?
  end

  test "create failure of link as a contact detail with invalid params" do
    invalid_link = "invalid/url@#"
    link = LinkContactDetail.new(value: invalid_link, user_id: @user.id)
    assert_not link.valid?
  end
end
