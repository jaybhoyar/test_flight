# frozen_string_literal: true

class Api::V1::Admin::SlackTeamsController < Api::V1::BaseController
  protect_from_forgery except: [:event, :install_url]
  skip_before_action :load_organization, only: [:event, :slack_callback]
  skip_before_action :authenticate_user_for_api
  skip_before_action :authenticate_user_using_x_auth_token, only: [:slack_callback, :event]
  before_action :load_slack_team, only: [:channel_names, :destroy]
  before_action :load_slack_integration_service
  before_action :find_organization, only: :slack_callback
  before_action :check_code_from_slack, only: [:slack_callback]

  def channel_names
    if @slack_team
      render json: { channel_names: @slack_team.channels }
    else
      render json: { channel_names: [] }
    end
  end

  def install_url
    url = @slack_integration_service.generate_install_url(@organization)
    render json: { url: }
  end

  def slack_callback
    if @slack_integration_service.verify_oauth_access_and_save(params[:code], @organization)
      redirect_to @organization_setting_url,
        notice: "Slack autorization was success."
    else
      redirect_to @organization_setting_url
    end
  end

  # This is a webhook to receive the message sent on channels.
  def event
    if params[:challenge].present?
      # Required register the webhook on slack.
      # It expect the first request to respond with the challenge attached in the request for validation purpose
      render json: { challenge: params[:challenge] }
    else
      # Subsequent request would be received here
      # No need to respond with any details.
    end
  end

  def destroy
    @slack_team.revoke
    @slack_team.destroy!
    render json: { message: "Slack integration has been successfully removed." }
  end

  private

    def check_code_from_slack
      @organization_setting_url = "#{@organization.root_url}desk/settings/integrations"
      unless params[:code]
        flash[:error] = "Slack authorization was not completed."
        redirect_to(@organization_setting_url) && return
      end
    end

    def load_slack_team
      @slack_team = @organization.slack_team
    end

    def load_slack_integration_service
      @slack_integration_service = Desk::Integrations::Slack::IntegrationService.new
    end

    def find_organization
      @organization = Organization.find_by(subdomain: params[:subdomain])
    end
end
