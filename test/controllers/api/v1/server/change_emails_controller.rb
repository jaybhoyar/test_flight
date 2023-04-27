# frozen_string_literal: true

class Api::V1::Server::ChangeEmailsController < Api::V1::Server::BaseController
  before_action :set_organization, :set_user

  def update
    if @user.update(email: params[:user][:new_email])

      render json: { success: true }
    else
      logger.error "Error while updating email #{@user.error_sentence}"
      render json: { success: false, error: @user.error_sentence }, status: :unprocessable_entity
    end
  end

  private

    def set_user
      @user = User.find_by(email: params[:user][:email], organization_id: @organization.id)

      unless @user
        render json: {
          success: false,
          error: t("resource.not_found", resource_name: "User")
        }, status: :not_found and return
      end
    end
end
