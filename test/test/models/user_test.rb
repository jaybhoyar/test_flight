# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @group = create :group
    @organization = @group.organization
    @agent_role = create :organization_role_agent, organization: @organization
    @admin_role = create :organization_role_admin, organization: @organization
    @user = create(:user, role: @agent_role, organization: @organization)
    @group.group_members.create(user: @user)
  end

  def test_the_length_of_name
    user1 = build :user, first_name: "Hubert Blaine Wolfeschlegelsteinhausenbergerdorff", last_name: "Hubert Blaine Wolfeschlegelsteinhausenbergerdorff"
    assert user1.valid?
  end

  def test_agent_or_owner
    user1 = create :user, email: "john1@example.com", organization: @organization, role: nil
    user2 = create :user, email: "john2@example.com", organization: @organization, role: @agent_role
    user3 = create :user, email: "john3@example.com", organization: @organization, role: @admin_role

    assert_not user1.member?
    assert user2.member?
    assert user3.member?
  end

  def test_that_same_email_can_be_used_for_different_organizations
    user1 = create :user, email: "john@example.com", organization: @organization
    user2 = build :user, email: "john@example.com"

    assert user2.valid?
  end

  def test_that_same_email_cannot_be_used_for_single_organization
    user1 = create :user, email: "john@example.com", organization: @organization
    user2 = build :user, email: "john@example.com", organization: @organization

    assert_not user2.valid?
  end

  def test_should_create_for_valid_default_role
    assert_equal @user.role.name, "Agent"
  end

  def test_should_not_create_for_invalid_default_role
    assert_not_equal @user.role, "admin"
  end

  def test_should_return_active_assigned_tickets_count_of_an_agent
    statuses = [
      "new",
      "open",
      "on_hold",
      "waiting_on_customer",
      "resolved",
      "closed",
    ]

    inactive_statuses = ["trash", "closed", "spam"]

    tickets = create_list(:ticket, 10, status: statuses.sample, agent: @user)
    active_assigned_tickets = tickets.select do |ticket|
                                inactive_statuses.exclude?(ticket[:status])
                              end
    assert_equal @user.active_assigned_tickets.count, active_assigned_tickets.count
  end

  def test_should_create_default_primary_email_contact_details_for_newly_created_user
    assert @user.email_contact_details.present?
    assert @user.email_contact_details.first.primary?
  end

  def test_should_reject_blank_values_for_nested_phone_contact_details
    blank_phone_contact_details = {
      "phone_contact_details_attributes": {
        "0": {
          "value": "",
          "_destroy": false,
          "id": ""
        }
      }
    }

    assert_difference "@user.phone_contact_details.count", 0 do
      @user.update(blank_phone_contact_details)
    end
  end

  def test_should_accept_non_blank_values_for_nested_phone_contact_details
    non_blank_phone_contact_details = {
      "phone_contact_details_attributes": {
        "0": {
          "value": "123455667",
          "_destroy": false,
          "id": ""
        }
      }
    }

    assert_difference "@user.phone_contact_details.count", 1 do
      @user.update(non_blank_phone_contact_details)
    end
  end

  def test_should_reject_blank_values_for_nested_link_contact_details
    blank_link_contact_details = {
      "link_contact_details_attributes": {
        "0": {
          "value": "",
          "_destroy": false,
          "id": ""
        }
      }
    }

    assert_difference "@user.link_contact_details.count", 0 do
      @user.update(blank_link_contact_details)
    end
  end

  def test_should_accept_non_blank_values_for_nested_link_contact_details
    non_blank_link_contact_details = {
      "link_contact_details_attributes": {
        "0": {
          "value": "https://dribbble.com/ethan_hunt",
          "_destroy": false,
          "id": ""
        }
      }
    }

    assert_difference "@user.link_contact_details.count", 1 do
      @user.update(non_blank_link_contact_details)
    end
  end
end
