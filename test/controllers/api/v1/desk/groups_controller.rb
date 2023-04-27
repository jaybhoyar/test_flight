# frozen_string_literal: true

class Api::V1::Desk::GroupsController < Api::V1::BaseController
  before_action :load_group!, only: [:show, :update]
  before_action :load_groups!, only: :destroy_multiple
  before_action :ensure_access_to_manage_groups!, only: [:new, :create, :update, :destroy_multiple]
  before_action :load_group_organization_carrier, only: [:new, :show, :index]

  def index
    @groups = @organization.groups.includes(preload_tables).order(:name)

    if params[:user_id].present?
      @groups = @groups.joins(:users).where(users: { id: params[:user_id] })
    end

    if params[:term].present?
      @groups = @groups.where("name ILIKE ?", "%#{params[:term]}%")
    end
  end

  def show
    render
  end

  def update
    if @group.update(group_params)
      render json: { notice: "Group has been successfully updated." }, status: :ok
    else
      render json: { errors: @group.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create
    group = @organization.groups.new(group_params)

    if group.save
      render json: { notice: "Group has been successfully created." }, status: :ok
    else
      render json: { errors: group.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy_multiple
    service = Desk::Groups::DeletionService.new(@groups)
    service.process

    if service.success?
      render json: { notice: service.response }, status: :ok
    else
      render json: { errors: service.errors }, status: :unprocessable_entity
    end
  end

  private

    def group_params
      params.require(:group).permit(
        :id, :name, :description, :business_hour_id,
        user_ids: []
      )
    end

    def preload_tables
      if params[:load_details].present?
        [:users, :tickets]
      else
        []
      end
    end

    def load_group!
      @group = @organization.groups.includes(:users).find_by!(id: params[:id])
    end

    def load_groups!
      @groups = @organization.groups
        .includes(:group_members, :round_robin_agent_slots, :actions, :conditions)
        .where!(id: params[:group][:ids])
    end

    def load_group_organization_carrier
      @group_organization_carrier = GroupOrganizationCarrier.new(@organization)
    end
end
