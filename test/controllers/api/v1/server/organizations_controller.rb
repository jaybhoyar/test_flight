# frozen_string_literal: true

class Api::V1::Server::OrganizationsController < Api::V1::Server::BaseController
  include ApiException
  before_action :load_organization, only: [:update]

  def create
    @organization = Organization.find_by(subdomain: organization_params.dig(:subdomain))

    if @organization.present?
      json_response = update_organization(organization_params.except(:subdomain))

      if json_response[:success]
        render json: json_response, status: :ok
      else
        logger.error "Error while updating organization from server #{json_response[:error]}"
        render json: json_response, status: :unprocessable_entity
      end
    else
      service = Desk::Organizations::CreateService.new(organization_params)
      @organization = service.process

      render json: service.response, status: service.status
    end
  end

  def update
    json_response = update_organization(organization_update_params)
    if json_response[:success]
      render json: json_response, status: :ok
    else
      render json: json_response, status: :unprocessable_entity
    end
  end

  private

    def organization_params
      @_organization_params ||= params.require(:organization).permit(
        :name,
        :subdomain,
        :api_key,
        :enabled,
        :auth_app_url,
        :auth_app_id,
        :auth_app_secret,
      )
    end

    def update_organization(update_params)
      ActiveRecord::Base.transaction do
        @organization.update!(update_params)
        { success: true, notice: t("resource.update", resource_name: "Organization") }
      rescue ActiveRecord::RecordInvalid => exception
        { success: false, error: exception.record.error_sentence }
      end
    end

    def organization_update_params
      permitted_params = params.require(:organization).permit(
        :cancelled_at,
        :auth_app_url,
        :name,
        :api_key,
        :enabled,
        :favicon_url,
        :subdomain,
      )

      if (@organization.cancelled? && permitted_params[:cancelled_at].nil?) || permitted_params[:cancelled_at]
        status = permitted_params[:cancelled_at] ? :cancelled : :active
        permitted_params.merge(status: Organization.statuses[status])
      else
        permitted_params
      end

      if params[:organization_neeto_applications]
        organization = params[:organization_neeto_applications].find { |app|
 app["app_name"] == app_secrets.client_app_name }
        if organization.present?
          permitted_params.merge!(enabled: organization["enabled"])
        end
      end

      permitted_params
    end

    def load_organization
      @organization = Organization.find_by!(subdomain: params[:subdomain])
    end
end
