# frozen_string_literal: true

class Api::V1::Desk::CustomersController < Api::V1::BaseController
  before_action :load_customer!, only: %i[show update destroy]
  before_action :fetch_time_zones, only: %i[new show index]
  before_action :load_customers, only: [:destroy_multiple]

  before_action :ensure_access_to_manage_customer_details!, only: [:new, :create, :update]

  def index
    @customers = if search?
      Search::User.new(@organization, customer_params[:search_string]).search
    else
      User.where(organization: @organization)
    end

    @customers = @customers.includes(:company, :customer_detail, :open_tickets).where(role: nil).order(sort_by)
    service = Desk::Customers::FilterService.new(@customers, params)
    @customers = service.process
    @total_count = service.total_count
  end

  def new
    render
  end

  def create
    service = customer_creator_service
    service.process

    if service.errors.present?
      render json: { error: service.errors }, status: service.status
    else
      render json: service.response, status: service.status
    end
  end

  def show
    @companies = @organization.companies
  end

  def update
    if current_password_incorrect?
      return incorrect_current_password_error
    end

    service = customer_update_service
    service.process

    if service.errors.present?
      render json: { errors: service.errors }, status: service.status
    else
      render json: service.response, status: service.status
    end
  end

  def destroy
    if @customer.destroy
      render json: { notice: "Customer was deleted successfully." }, status: :ok
    else
      render json: { errors: @customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy_multiple
    service = Desk::Customers::DeletionService.new(@customers)
    service.process

    if service.success?
      render status: :ok, json: { notice: service.response }
    else
      render status: :unprocessable_entity, json: { errors: service.errors }
    end
  end

  private

    def all_organization_contacts
      @organization.contacts
    end

    def load_customer!
      @customer = User.find_by!(id: params[:id], organization: @organization)
    end

    def load_customers
      @customers = User
        .includes(
          :customer_detail, :tickets, :comments, :message_events, :messages,
          :email_contact_details, :phone_contact_details, :link_contact_details, :notes, :group_members,
          :devices, :organization
        )
        .where(id: params[:customer][:ids], organization: @organization)
    end

    def customer_params
      return {} if params[:customer].blank?

      nested_attributes = [
        :label,
        :value,
        :_destroy,
        :id
      ]

      email_contact_details_attrs = [
        *nested_attributes,
        :primary
      ]

      customer_detail_attrs = [
        :language,
        :time_zone,
        :about,
        :twitter_id,
        :twitter_screen_name,
        tags: [
          :id
        ]
      ]

      customer_attributes = [
        :first_name,
        :last_name,
        :status,
        :company_id,
        :page_index,
        :page_size,
        :password,
        :search_string,
        :column,
        :direction,
        email_contact_details_attributes: email_contact_details_attrs,
        link_contact_details_attributes: nested_attributes,
        phone_contact_details_attributes: nested_attributes,
        customer_detail_attributes: customer_detail_attrs
      ]

      params.require(:customer).permit(*customer_attributes)
    end

    def fetch_time_zones
      @time_zone_carrier = TimeZoneCarrier.new
    end

    def customer_creator_service
      Desk::Customers::CreatorService.new(
        @organization,
        current_user,
        customer_params
      )
    end

    def customer_update_service
      Desk::Customers::UpdateService.new(
        @organization,
        @customer,
        customer_params
      )
    end

    def current_password_incorrect?
      current_password = params.dig(:customer, :current_password)

      current_password.present? && !@customer.valid_password?(current_password)
    end

    def incorrect_current_password_error
      render json: { error: "Current password is incorrect. Please try again." }, status: :unprocessable_entity
    end

    def search?
      params.dig(:customer, :search_string).present?
    end

    def sort_by
      column = customer_params[:column] || "created_at"
      direction = customer_params[:direction] || "desc"
      { column => direction }
    end
end
