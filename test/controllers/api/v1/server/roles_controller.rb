# frozen_string_literal: true

class Api::V1::Server::RolesController < Api::V1::Server::BaseController
  skip_before_action :load_organization, raise: false
  before_action :set_organization
  before_action :set_user

  def show
    return render json: defaults if !@organization.respond_to? :roles

    if @user.present?
      return render json: defaults if @user.role.nil?

      roles = @organization.roles.map { |role| role.name }
      render json: { active_role: @user.role.name, roles: }
    else
      render json: defaults
    end
  end

  private

    def defaults
      { active_role: "Admin", roles: ["Admin", "Standard"] }
    end

    def set_user
      @user = @organization.users.find_by(email: params[:email])
    end
end
