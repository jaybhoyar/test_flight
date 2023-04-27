# frozen_string_literal: true

class Auth::ChainAuthenticationsController < ActionController::Base
  def index
    after_sign_in_path = params[:redirect_to] || Rails.application.secrets.routes[:app][:after_chain_sign_in_path]

    if user_signed_in?
      redirect_to after_sign_in_path
    else
      session[:user_return_to] = after_sign_in_path
      session[:chain_authentication] = "yes"
      redirect_to user_doorkeeper_omniauth_authorize_url
    end
  end
end
