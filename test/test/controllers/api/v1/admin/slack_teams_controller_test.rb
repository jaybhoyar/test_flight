# frozen_string_literal: true

require "test_helper"
require "mocha"

class Api::V1::Admin::SlackTeamsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user, :admin
    @organization = @user.organization
    @slack_team = create(:slack_team, organization: @organization)
    sign_in @user

    host! test_domain(@organization.subdomain)
  end

  def test_that_channel_name_api_works
    SlackTeam.any_instance.stubs(:channels).returns(["website", "general"])
    post channel_names_api_v1_admin_slack_teams_url, headers: headers(@user)

    assert_response :ok
    assert_equal 2, json_body["channel_names"].count
    assert_includes json_body["channel_names"], "general"
  end

  def test_install_url
    post install_url_api_v1_admin_slack_teams_url, headers: headers(@user)

    assert_response :ok
    assert_equal ["url"], json_body.keys
  end

  def test_revoke_slack
    SlackTeam.any_instance.stubs(:revoke).returns(true)
    delete api_v1_admin_slack_teams_url(@slack_team),
      headers: headers(@user)

    assert_response :ok
    assert_equal 0, SlackTeam.count
  end

  def test_event_webhook_first_request
    challenge = "THIS IS A DIFFCULT CHALLENGE"
    post event_api_v1_admin_slack_teams_url(@slack_team),
      params: { challenge: },
      headers: headers(@user)

    assert_response :ok
    assert_equal json_body["challenge"], challenge
  end

  def test_event_webhook_later_request
    post event_api_v1_admin_slack_teams_url(@slack_team),
      params: event_params,
      headers: headers(@user)

    assert_response :no_content
  end

  private

    def event_params
      {
        "token" => "token",
        "team_id" => "team_id",
        "api_app_id" => "api_app_id",
        "event" => {
          "client_msg_id" => "client_msg_id",
          "type" => "message",
          "text" => "This is a dummy message.",
          "user" => "user_id",
          "ts" => "timestamp",
          "team" => "team_id",
          "blocks" => [
            {
              "type" => "rich_text",
              "block_id" => "6bF",
              "elements" => [
                {
                  "type" => "rich_text_section",
                  "elements" => [
                    {
                      "type" => "text",
                      "text" => "This is a dummy message."
                    }
                  ]
                }
              ]
            }
          ],
          "channel" => "C018MTZ3UDQ",
          "event_ts" => "timestamp",
          "channel_type" => "channel"
        },
        "type" => "event_callback",
        "event_id" => "event_id",
        "event_time" => "timestamp",
        "authed_users" => ["user_id"],
        "slack_team" => { "team_id" => "team_id" }
      }
    end
end
