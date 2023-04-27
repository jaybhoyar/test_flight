# frozen_string_literal: true

class Desk::Customers::EmailSubscriptionsController < ApplicationController
  before_action :load_customer!

  def show
    if !@customer.has_active_email_subscription
      @customer.update!(has_active_email_subscription: true)
      @subscribed = true
    end
  end

  private

    def load_customer!
      @customer = User.find_by_signature(params[:signature])
    end
end
