# frozen_string_literal: true

class Desk::Customers::EmailUnsubscriptionsController < ApplicationController
  before_action :load_customer!

  def show
    if @customer.has_active_email_subscription
      @customer.unsubscribe_from_outbound_messages!
      @unsubscribed = true
    end
  end

  private

    def load_customer!
      @customer = User.find_by_signature(params[:signature])
    end
end
