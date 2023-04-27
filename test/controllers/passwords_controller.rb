# frozen_string_literal: true

class PasswordsController < ApplicationController
  before_action :load_user!
  before_action :ensure_user_has_access, except: [:new]

  def new
    @errors = request.flash.alert
  end

  def edit
    render
  end

  private

    def load_user!
      original_token = params[:reset_password_token]
      reset_password_token = Devise.token_generator.digest(User, :reset_password_token, original_token)

      @user = User.find_by(reset_password_token:)
    end

    def ensure_user_has_access
      if @user.nil? || token_expired?
        redirect_to "/users/password/new", alert: [ alert_message ]
      end
    end

    def token_expired?
      @user.present? &&
        @user.persisted? &&
        !@user.reset_password_period_valid?
    end

    def alert_message
      "The link has expired. You can request for a new one below."
    end
end
