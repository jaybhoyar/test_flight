# frozen_string_literal: true

class Desk::Integrations::Slack::IntegrationService
  REDIRECT_URI = "#{Rails.application.secrets.host}/api/v1/admin/slack_teams/slack_callback?subdomain="
  attr_reader :token

  def initialize(token = "")
    @token = token
  end

  def generate_install_url(organization)
    scope = "channels:write,chat:write:bot,channels:read,groups:read,groups:write,users:read,users:read.email"
    "https://slack.com/oauth/authorize?client_id=#{Rails.application.secrets.slack[:client_id]}&state=#{organization.id}&scope=#{scope}&redirect_uri=#{REDIRECT_URI}#{organization.subdomain}"
  end

  def verify_oauth_access_and_save(code, organization)
    response = Slack::Web::Client.new.oauth_access(
      client_id: Rails.application.secrets.slack[:client_id],
      client_secret: Rails.application.secrets.slack[:client_secret],
      code:,
      redirect_uri: REDIRECT_URI + organization.subdomain
    )
    save_slack_team(response, organization)
  end

  def save_slack_team(response, organization)
    slack_team = organization.slack_team || organization.build_slack_team
    slack_team.update(
      access_token: response.access_token,
      team_id: response.team_id,
      team_name: response.team_name,
      slack_user_id: response.user_id,
      enabled: true
    )
  end

  def client
    @client ||= Slack::Web::Client.new(token:)
  end

  def channel_exists?(channel)
    begin
      channels = client.conversations_list(
        limit: 1000, exclude_archived: true,
        types: "public_channel, private_channel").channels
      channels.detect { |c| c.name == channel }
    rescue Slack::Web::Api::Errors::SlackError => exception
      false
    end
  end

  def channels
    begin
      channels_list
        .map(&:name)
        .sort
    rescue Slack::Web::Api::Errors::SlackError => exception
      []
    end
  end

  def channels_list
    channels_list = []
    pagination_cursor = "initial"
    while pagination_cursor.present?
      slack_response = client.conversations_list(get_slack_request_params(pagination_cursor))
      updated_cursor_value = slack_response.response_metadata.next_cursor
      break if pagination_cursor == updated_cursor_value

      channels_list << slack_response.channels
      pagination_cursor = updated_cursor_value
    end
    channels_list.flatten!(1)
  end

  def get_slack_request_params(pagination_cursor)
    slack_params = { limit: 1000, exclude_archived: true, types: "public_channel, private_channel" }
    slack_params.merge!(cursor: pagination_cursor) if pagination_cursor.present? && pagination_cursor != "initial"
    slack_params
  end

  def post_message(selected_channel, message)
    begin
      client.chat_postMessage(channel: selected_channel, text: message)
    rescue Slack::Web::Api::Errors::ChannelNotFound => exception
      { error: true, description: "Channel not found." }
    end
  end

  def revoke
    client.auth_revoke
  end
end
