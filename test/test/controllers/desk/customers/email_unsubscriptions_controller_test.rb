# frozen_string_literal: true

require "test_helper"

class Desk::Customers::EmailUnsubscriptionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @user.update!(has_active_email_subscription: true)
    @organization = @user.organization
    @outbound_message = create(:outbound_message, organization: @organization)

    host! test_domain(@organization.subdomain)
  end

  def test_show_success
    get desk_customer_unsubscribe_url(@user.id, @user.unsubscription_token)

    assert_response :ok
    assert_select "h3", "You have unsubscribed successfully. Thank you."
  end

  def test_show_success_if_already_unsubscribed
    @user.unsubscribe_from_outbound_messages!
    assert_equal false, @user.has_active_email_subscription

    get desk_customer_unsubscribe_url(@user.id, @user.unsubscription_token)

    assert_response :ok
    assert_select "h3", "You have already unsubscribed."
  end
end
