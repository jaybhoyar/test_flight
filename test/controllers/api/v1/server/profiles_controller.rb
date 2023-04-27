# frozen_string_literal: true

class Api::V1::Server::ProfilesController < Api::V1::Server::BaseController
  include SSOHelpers

  before_action :set_organization

  def update
    return if !user?

    @user = User.find_or_initialize_by(
      email: profile_params[:email],
      organization_id: @organization.id
    )

    @user.password = default_password if @user.new_record?

    if @user.update(profile_params.except(:email).merge(user_attrs))
      render json: { success: true }
    else
      render json: { success: false, error: @user.error_sentence }, status: :unprocessable_entity
    end
  end

  private

    def user_attrs
      if @user.respond_to? :role
        {
          active: is_active?,
          role: user_organization_role
        }
      else
        {
          active: is_active?
        }
      end
    end

    def profile_params
      @_profile_params ||= params.require(:profile).permit(
        :email,
        :first_name,
        :last_name,
        :profile_image_url,
        :time_zone,
        :date_format,
        :deactivated_at
      )
    end

    def user_app_roles_params
      @_user_app_roles_params ||= params.require(:profile).permit(
        app_roles: [:app_name, :active_role]
      )[:app_roles]
    end

    def user_organization_role
      return @user.role if user_app_roles_params&.length == 0

      user_app = user_app_roles_params&.find { |app| app[:app_name] == app_secrets.client_app_name }
      return @user.role if user_app.nil?

      @organization.roles.find_by(name: user_app[:active_role])
    end

    def is_active?
      if sso_enabled?
        return false if !params[:profile]["deactivated_at"].nil?
        return true if params[:profile][:role] == "owner"

        app = params[:profile][:neeto_apps].find { |app| app["app_name"] == app_secrets.client_app_name }
        return app["active"] if app.present?
      else
        true
      end
    end

    def user?
      return true if !sso_enabled?

      app = params[:profile][:neeto_apps]&.find { |app| app["app_name"] == app_secrets.client_app_name }
      app.present?
    end

    def app_secrets
      @_app_secrets ||= Rails.application.secrets
    end
end
