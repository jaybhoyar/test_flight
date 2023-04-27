# frozen_string_literal: true

class Api::V1::Admin::Users::SessionsController < Devise::SessionsController
  include ApiException
  include SimpleToken
  include Sessions

  protect_from_forgery except: [:create, :create_when_no_organization]
  skip_before_action :load_organization, only: :email_organization_details

  def create
    @resource = User.without_customers.find_for_database_authentication(
      email: user_params[:email],
      organization_id: @organization.id
    )

    do_signin
  end

  def create_when_no_organization
    if !verify_user_token || params[:email] != user_params[:email]
      return respond_with_error "Invalid token", 401
    end

    @resource = User.find_for_database_authentication(email: user_params[:email])

    do_signin
  end

  def destroy
    current_user&.go_offline
    current_user.reset_authentication_token!
    super
  end

  private

    def user_params
      params.require(:user).permit(:email, :password, :remember_me, :organization_id)
    end

    def render_auth_success
      redirect_to = session[:return_to] || redirect_to_path
      session[:return_to] = nil

      redirect_path = redirect_to.gsub(/\/?%20/, "")

      render status: :ok, json: {
        auth_token: @resource.authentication_token,
        redirect_to: redirect_path,
        name: @resource.name,
        id: @resource.id
      }
    end

    def do_signin
      if @resource && @resource.active? && perform_sign_in(user_params)
        render_auth_success
      else
        respond_with_error error_message, 401
      end
    end

    def redirect_to_path
      if @resource.can_only_view_manage_or_reply_to_tickets?
        "/desk/tickets/filters/unresolved"
      elsif !@resource.can_view_tickets?
        "/my/preferences"
      else
        stored_location_for(@resource)
        "/"
      end
    end
end
