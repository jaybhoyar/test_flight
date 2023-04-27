# frozen_string_literal: true

class HomeController < ApplicationController
  before_action :reset_chain_authentication_session, only: :index, if: -> { session[:chain_authentication] == "yes" }

  def index
    if user_signed_in?
      redirect_to URI.join(@organization.root_url, redirect_path).to_s
    else
      authenticate_user!
    end
  end

  def new
    render
  end

  private

    def redirect_path
      if !current_user.can_view_tickets?
        "/my/preferences"
      else
        "/desk/tickets/filters/unresolved"
      end
    end

    def reset_chain_authentication_session
      session[:chain_authentication] = "no"
    end
end
