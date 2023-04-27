# frozen_string_literal: true

class Api::V1::Admin::UsersController < Api::V1::BaseController
  before_action :load_user!, only: [:update, :show]
  before_action :load_user_attributes, only: [:show, :update]
  before_action :load_users!, only: :destroy_multiple
  before_action :expire_cache!, only: [:create, :update, :destroy_multiple]

  before_action :ensure_access_to_manage_agents!, only: :create
  before_action :ensure_user_is_admin_or_the_account_owner, only: :update
  before_action :ensure_user_is_account_owner, only: :destroy_multiple
  before_action :validate_email_ids!, only: :create

  def index
    matched_users = if filter_params[:search_term].present?
      Search::User.new(@organization, filter_params[:search_term]).search
    else
      User.where(organization: @organization)
    end

    matched_users = matched_users.without_customers
    matched_users = Desk::Organizations::Users::FilterService.new(matched_users, filter_params).process

    @all_users = User.where(organization: @organization)
    @total_count = matched_users.count

    @users = matched_users.includes(:groups, role: :permissions)
      .order(order_by)
      .page(page_index)
      .per(page_limit)
  end

  def show
    render
  end

  def update
    update_service = Desk::Organizations::Users::UpdateService.new(
      @user,
      current_user,
      user_update_params
    )
    update_service.process

    render update_service.response
  end

  def create
    errors = []
    user_params[:emails].each do |email|
      service = user_creator_service(email)
      service.process
      errors << service.errors if service.errors.present?
    end

    if errors.present?
      render json: { error: errors.to_sentence }, status: :unprocessable_entity
    else
      render json: { notice: t("notice.generic.plural", resource: "Agent(s)", action: "invited") }, status: :ok
    end
  end

  def destroy_multiple
    service = Desk::Organizations::Users::DeletionService.new(@users)
    service.process

    if service.success?
      render json: { notice: service.response }, status: :ok
    else
      render json: { errors: service.errors }, status: :unprocessable_entity
    end
  end

  private

    def load_user!
      @user = User
        .includes(:permissions, :activities)
        .find_by!(id: params[:id], organization: @organization)
      @neeto_apps = neeto_apps
    end

    def load_users!
      @users = User
        .includes(
          :customer_detail, :tickets, :comments, :message_events, :messages,
          :email_contact_details, :phone_contact_details, :link_contact_details, :notes, :group_members,
          :devices, :organization
        )
        .where!(id: params[:user][:ids], organization: @organization)
    end

    def load_user_attributes
      @profile_attributes = UserProfileCarrier.new(current_user, @organization)
    end

    def ensure_user_is_admin_or_the_account_owner
      authorize @user, :can_update?
    end

    def ensure_user_is_account_owner
      @users.each do |user|
        authorize user, :can_destroy?
      end
    end

    def user_params
      params.require(:user).permit(
        :password, :organization_role_id, :status, :company_id, :time_zone, :first_name,
        :last_name, :date_format, :time_zone_offset, :email, emails: [])
    end

    def user_update_params
      params.require(:user).permit(
        :id, :email, :organization_role_id, :password, :first_name, :last_name, :time_zone, :company_id,
        :date_format, :available_for_desk, :available_for_chat, :continue_assigning_tickets, :unassign_tickets,
        :unassign_conversations, :status, :show_keyboard_shortcuts, :change_role,
        phone_contact_details_attributes: nested_attributes,
        link_contact_details_attributes: nested_attributes,
      )
    end

    def nested_attributes
      [:id, :value, :_destroy]
    end

    def filter_params
      params.permit(
        :available_for_desk, :column, :direction, :page_index, :page_size, :search_term, :status,
        role_ids: [], group_ids: []
      )
    end

    def validate_email_ids!
      @taken_emails = []
      user_params[:emails].each do |email|
        @taken_emails << email if @organization.users.exists?(email: email.downcase)
      end

      if @taken_emails.present?
        render json: {
          message: "#{"Email".pluralize(@taken_emails.length)} #{@taken_emails.to_sentence} already exists.",
          taken_emails: @taken_emails
        }, status: :unprocessable_entity
      end
    end

    def user_creator_service(email)
      Desk::Organizations::Users::CreatorService
        .new(@organization, current_user, invited_user_params(email))
    end

    def invited_user_params(email)
      {
        organization_role_id: user_params[:organization_role_id],
        status: user_params[:status],
        time_zone_offset: user_params[:time_zone_offset],
        email:
      }
    end

    def neeto_apps
      if Rails.env.test? || Rails.env.heroku? || !Rails.application.secrets.sso_enabled
        []
      else
        Rails.cache.fetch("organizations/#{@organization.subdomain}/neeto_apps", expires_in: 12.hours) do
          Organizations::NeetoAppsService.new(current_user).process["neeto_apps"]
        end
      end
    end

    def expire_cache!
      Rails.cache.delete_matched("#{@organization.cache_key}/users/*")
    end

    def filter_users_by_status(users)
      case user_params[:status]
      when "active"
        users.only_active
      when "deactivated"
        users.only_inactive
      else
        users
      end
    end

    def order_by
      column = filter_params[:column] || "created_at"
      direction = filter_params[:direction] || "desc"
      { column => direction }
    end

    def page_index
      filter_params[:page_index] || 1
    end

    def page_limit
      filter_params[:page_size] || 15
    end
end
