# frozen_string_literal: true

class Api::V1::Admin::OrganizationRolesController < Api::V1::BaseController
  before_action :load_organization_role!, only: [:show, :update, :destroy]
  before_action :load_agent_options, only: [:new, :show]
  before_action :ensure_access_to_manage_roles!, only: [:new, :create, :update, :destroy]

  def index
    @organization_roles = @organization.roles
  end

  def new
    @organization_role = @organization.roles.new
  end

  def create
    organization_role = @organization.roles.new(role_params)

    if organization_role.save
      render status: :ok, json: { notice: "Role has been successfully created." }
    else
      render status: :unprocessable_entity, json: { errors: organization_role.errors.full_messages }
    end
  end

  def show
    render
  end

  def update
    update_service.process
    render update_service.response
  end

  def destroy
    if @organization_role.destroy
      render json: { notice: "Role has been successfully deleted." }, status: :ok
    else
      render_unprocessable_entity(@organization_role.errors.full_messages)
    end
  end

  private

    def role_params
      params.require(:organization_role).permit(:id, :name, :kind, :description, permission_ids: [])
    end

    def load_organization_role!
      @organization_role = @organization.roles.find_by!(id: params[:id])
    end

    def load_agent_options
      @agent_options = @organization.users.without_customers
    end

    def update_service
      @_update_service ||= Desk::Organizations::Roles::UpdateService.new(@organization_role, params)
    end
end
