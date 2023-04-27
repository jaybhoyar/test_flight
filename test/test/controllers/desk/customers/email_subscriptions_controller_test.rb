# frozen_string_literal: true

require "test_helper"

class Desk::Customers::EmailSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @user.update!(has_active_email_subscription: false)
    @organization = @user.organization
    @outbound_message = create(:outbound_message, organization: @organization)

    host! test_domain(@organization.subdomain)
  end

  def test_show_success
    get desk_customer_subscribe_url(@user.id, @user.unsubscription_token)

    @user.reload

    assert_response :ok
    assert_equal true, @user.has_active_email_subscription
    assert_select "h3", "You have been subscribed successfully."
  end
end
