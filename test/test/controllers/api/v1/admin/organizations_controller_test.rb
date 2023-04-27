# frozen_string_literal: true

require "test_helper"
require "mocha"

class Api::V1::Admin::OrganizationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create :organization
    @user = create :user, organization: @organization
    @admin_permission_1 = Permission.find_or_create_by(name: "admin.manage_organization_settings", category: "Admin")
    role = create :organization_role, permissions: [@admin_permission_1]
    @user.update(role:)

    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_show_success
    get api_v1_admin_organization_url(@organization.api_key), headers: headers(@user)

    assert_response :ok
    assert_equal @organization.id, json_body["organization"]["id"]
    assert_equal @organization.name, json_body["organization"]["name"]
    assert_equal [
        "allow_anyone_to_submit_ticket",
        "api_key",
        "domain",
        "email_signin_enabled",
        "favicon_url",
        "id",
        "locale",
        "name",
        "subdomain",
        "url"
      ], json_body["organization"].keys.sort
  end

  def test_update_success
    organization_params = { organization: { name: "BigBinary" } }

    patch api_v1_admin_organization_url(@organization.api_key),
      params: organization_params,
      headers: headers(@user)
    @organization.reload
    assert_response :ok
    assert_equal "BigBinary", @organization.reload.name
  end

  def test_update_ticket_submission_permission_success
    organization_params = { organization: { allow_anyone_to_submit_ticket: true } }

    patch api_v1_admin_organization_url(@organization.api_key),
      params: organization_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal true, @organization.reload.allow_anyone_to_submit_ticket
  end

  def test_organization_can_be_updated_excluding_subdomain
    @organization.update(is_onboard: false)

    patch api_v1_admin_organization_path(@organization),
      params: { organization: { is_onboard: true } },
      headers: headers(@user)

    assert_response :ok
    assert @organization.reload.is_onboard
  end

  def test_organization_index_success
    get api_v1_admin_organizations_path, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["organizations"].size
  end

  def test_slack_attributes
    @slack_team = create :slack_team, organization: @organization

    SlackTeam.any_instance.stubs(:channels).returns(slack_channels)

    get api_v1_admin_organization_url(@organization.api_key), headers: headers(@user)

    assert_response :ok
    assert_equal ["organization", "slack_team", "is_sso_enabled"], json_body.keys
  end

  private

    def slack_channels
      ["website", "general"]
    end

    def subdomain_word
      Faker::Internet.domain_word[0..19]
    end
end
