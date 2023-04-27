# frozen_string_literal: true

class Api::V1::Admin::OrganizationsController < Api::V1::BaseController
  skip_before_action :authenticate_user_using_x_auth_token, only: %i[index new]
  before_action :ensure_access_to_manage_organization_settings!, only: %i[update destroy]

  def index
    @organizations = current_user.belonging_organizations
  end

  def show
    @is_sso_enabled = sso_enabled?
    load_slack
  end

  def update
    if @organization.update(organization_params)
      render status: :ok, json: { notice: "Organization has been successfully updated." }
    else
      render status: :unprocessable_entity, json: { errors: @organization.errors.full_messages }
    end
  end

  def destroy
    @organization.update! \
      status: :cancelled,
      cancelled_by_org_user_id: current_user.id,
      cancelled_at: DateTime.current

    render json: { redirect_url: root_path, notice: "Organization has been successfully deleted." }, status: :ok
  end

  private

    def organization_params
      params.require(:organization).permit(
        :allow_anyone_to_submit_ticket, :is_onboard
      )
    end

    def load_slack
      @slack_team = @organization.slack_team
    end
end
