# frozen_string_literal: true

class Api::V1::Desk::EmailConfigurationsController < Api::V1::BaseController
  before_action :load_email_configuration!, only: [:destroy, :update]

  def index
    @email_configurations = @organization.email_configurations
  end

  def create
    @email_configuration = Desk::Mailboxes::EmailConfigurations::CreateService.new(
      @organization,
      email_configuration_params).process

    if @email_configuration.valid?
      render json: {
        notice: "Mailbox has been successfully created.",
        email_configuration: @email_configuration
          .reload
          .slice(:id, :email, :from_name, :custom_name, :forward_to_email)
      }, status: :ok
    else
      render json: {
        errors: @email_configuration.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if update_email_configuration
      render json: {
        notice: "Email Configuration has been successfully updated."
      }, status: :ok
    else
      render json: {
        errors: @email_configuration.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @email_configuration.destroy
      render json: {
        notice: "Mailbox has been successfully deleted."
      }, status: :ok
    else
      render json: {
        errors: @email_configuration.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

    def email_configuration_params
      params.require(:email_configuration).permit(:email, :from_name, :custom_name)
    end

    def load_email_configuration!
      @email_configuration = @organization.email_configurations.find_by!(id: params[:id])
    end

    def update_email_configuration
      update_service = Desk::Mailboxes::EmailConfigurations::UpdateService.new(
        @email_configuration,
        email_configuration_params
      )

      update_service.process
    end
end
