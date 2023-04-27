# frozen_string_literal: true

class Admin::BaseController < ActionController::Base
  include AppUrlLoader
  include ErrorHandlers

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :ensure_user_is_logged_in!
  before_action :load_profile_attributes

  layout "application"

  private

    def ensure_user_is_logged_in!
      unless user_signed_in?
        store_location
        authenticate_user!
      end
    end

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
    end

    def after_sign_out_path_for(resource)
      root_path
    end

    def load_profile_attributes
      @profile_attributes = UserProfileCarrier.new(current_user, @organization).profile_attributes
    end

    def store_location
      session[:return_to] = request.fullpath
    end
end
