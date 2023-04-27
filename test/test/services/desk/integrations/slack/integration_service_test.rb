# frozen_string_literal: true

require "test_helper"
require "mocha"

class Desk::Integrations::Slack::IntegrationServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
    @slack_integration_service = Desk::Integrations::Slack::IntegrationService.new("token")
  end

  def test_generate_install_url
    url = @slack_integration_service.generate_install_url(@organization)
    assert_equal installation_url, url
  end

  def test_correct_channel_exists
    selected_channel = "general"
    Desk::Integrations::Slack::IntegrationService.any_instance.stubs(:channel_exists?).returns(true)
    assert @slack_integration_service.channel_exists?(selected_channel)
  end

  def test_incorrect_channel_exists
    selected_channel = "general1"
    Desk::Integrations::Slack::IntegrationService.any_instance.stubs(:channel_exists?).returns(false)
    refute @slack_integration_service.channel_exists?(selected_channel)
  end

  def test_should_update_slack_team
    status = @slack_integration_service.save_slack_team(slack_response, @organization)

    assert status
    assert_equal @organization.slack_team.access_token, slack_response.access_token
  end

  private

    def installation_url
      redirect_uri = "#{Rails.application.secrets.host}/api/v1/admin/slack_teams/slack_callback?subdomain=#{@organization.subdomain}"
      scope = "channels:write,chat:write:bot,channels:read,groups:read,groups:write,users:read,users:read.email"
      "https://slack.com/oauth/authorize?client_id=#{Rails.application.secrets.slack[:client_id]}&state=#{@organization.id}&scope=#{scope}&redirect_uri=#{redirect_uri}"
    end

    def slack_response
      @Response = Struct.new(:access_token, :team_id, :team_name, :user_id)
      @Response.new("access_token", "team_id", "team_name", "user_id")
    end
end
