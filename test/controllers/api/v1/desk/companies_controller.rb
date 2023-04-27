# frozen_string_literal: true

class Api::V1::Desk::CompaniesController < Api::V1::BaseController
  before_action :load_company!, only: [:update, :show, :destroy]
  before_action :load_companies!, only: :destroy_multiple

  before_action :ensure_access_to_manage_companies!, only: [:create, :update, :destroy_multiple]

  def index
    get_companies
  end

  def show
    @customers = @company.customers
    @tickets = @company.tickets
  end

  def create
    @company = @organization.companies.new(company_params.except(:add_company_to_existing_customers))

    if @company.save
      render json: { company: @company }
    else
      render status: :unprocessable_entity, json: { errors: @company.errors.full_messages }
    end
  end

  def update
    if @company.update(company_params.except(:add_company_to_existing_customers))
      if company_params[:add_company_to_existing_customers] == "true"
        @company.add_to_existing_customers(company_params[:company_domains_attributes], @organization)
      end
      render status: :ok, json: { notice: "Company has been successfully updated." }
    else
      render status: :unprocessable_entity, json: { errors: @company.errors.full_messages }
    end
  end

  def destroy
    company_deletion_service = Desk::Companies::DeletionService.new([@company])
    company_deletion_service.process

    if company_deletion_service.success?
      render status: :ok, json: { notice: company_deletion_service.response }
    else
      render status: :unprocessable_entity, json: { error: companies_deletion_service.errors }
    end
  end

  def destroy_multiple
    companies_deletion_service = Desk::Companies::DeletionService.new(@companies)
    companies_deletion_service.process

    if companies_deletion_service.success?
      render status: :ok, json: { notice: companies_deletion_service.response }
    else
      render status: :unprocessable_entity, json: { error: companies_deletion_service.errors }
    end
  end

  private

    def company_params
      return {} unless params[:company].present?

      params.require(:company).permit(
        :id, :name, :description, :notes,
        :page_index, :page_size, :search_term, :column, :direction,
        :add_company_to_existing_customers,
        company_domains_attributes: [:name, :_destroy, :id])
    end

    def get_companies
      @companies = @organization.companies.includes(:customers).order(sort_by)
      @total_count = @companies.count

      if search?
        @companies = @companies.where("name ILIKE ?", "%#{params[:company][:search_term]}%")
      end

      if paginate?
        @companies = @companies.page(company_params[:page_index]).per(params[:company][:page_size])
      end
    end

    def load_company!
      @company = @organization.companies.find_by!(id: params[:id])
    end

    def load_companies!
      @companies = @organization.companies.where!(id: params[:company][:ids])
    end

    def search?
      params[:company] && params[:company][:search_term].present?
    end

    def paginate?
      params[:company] && params[:company][:page_index].present?
    end

    def sort_by
      if params[:company].present?
        column = params[:company][:column] || "name"
        direction = params[:company][:direction] || "asc"
        { column => direction }
      end
    end
end
