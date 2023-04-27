# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::TicketFieldsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)
    @manage_permission = Permission.find_or_create_by(name: "admin.manage_ticket_fields", category: "Admin")
    role = create :organization_role, permissions: [@manage_permission]
    @user.update(role:)
  end

  def test_index_success
    ticket_ticket_field = create(
      :ticket_field,
      organization: @organization)
    customer_ticket_field = create(
      :ticket_field,
      :textarea,
      organization: @organization)

    get api_v1_desk_ticket_fields_url, headers: headers(@user)
    assert_includes response.body, ticket_ticket_field.id
  end

  def test_that_ticket_field_is_created_with_ticket_options
    payload = {
      ticket_field: {
        agent_label: "What is your name?",
        is_required: true,
        kind: "text",
        options: [],
        is_required_for_agent_when_closing_ticket: true
      }
    }

    assert_difference "Desk::Ticket::Field.count", 1 do
      post api_v1_desk_ticket_fields_url(payload), headers: headers(@user)
    end
    assert_response :ok
  end

  def test_that_create_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    payload = {
      ticket_field: {
        agent_label: "What is your name?",
        is_required: true,
        kind: "text",
        options: [],
        is_required_for_agent_when_closing_ticket: true
      }
    }

    post api_v1_desk_ticket_fields_url(payload), headers: headers(@user)
    assert_response :forbidden
  end

  def test_that_ticket_field_is_not_created_with_invalid_data
    payload = {
      ticket_field: {
        agent_name: nil,
        is_required: nil,
        kind: nil,
        options: nil
      }
    }

    assert_no_difference "Desk::Ticket::Field.count" do
      post api_v1_desk_ticket_fields_url(payload), headers: headers(@user)
    end
    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Agent label can't be blank"
  end

  def test_that_ticket_field_data_is_returned
    field = create(:ticket_field, organization: @organization)
    get api_v1_desk_ticket_field_url(field), headers: headers(@user)

    assert_response :ok

    assert_equal \
      [
        "agent_label", "customer_label", "display_kind", "display_order", "field_options", "id", "is_editable_by_customer",
        "is_required", "is_required_for_agent_when_closing_ticket", "is_required_for_agent_when_submitting_form",
        "is_required_for_customer_when_submitting_form", "is_shown_to_customer", "is_system",
        "kind", "state", "ticket_field_options_attributes", "ticket_field_regex_attributes",
      ],
      json_body["ticket_field"].keys.sort
  end

  def test_that_ticket_field_is_updated
    field = create(
      :ticket_field,
      organization: @organization,
      agent_label: "Which browser you are using?")
    assert_equal "Which browser you are using?", field.agent_label
    assert_equal false, field.is_required_for_agent_when_closing_ticket

    payload = {
      ticket_field: {
        agent_label: "Which computer you are using?",
        is_required: true,
        kind: "text",
        options: [],
        is_required_for_agent_when_closing_ticket: true
      }
    }
    put api_v1_desk_ticket_field_url(field, payload), headers: headers(@user)

    assert_response :ok
    assert_equal "Ticket Field has been successfully updated.", json_body["notice"]
    assert_equal "Which computer you are using?", field.reload.agent_label
    assert_equal true, field.is_required_for_agent_when_closing_ticket
  end

  def test_ability_to_change_ticket_field_status
    field = create(
      :ticket_field,
      organization: @organization,
      agent_label: "Which browser you are using?")
    assert_equal "Which browser you are using?", field.agent_label
    assert_equal "active", field.state

    payload = {
      ticket_field: {
        state: "inactive"
      }
    }
    put api_v1_desk_ticket_field_url(field, payload), headers: headers(@user)

    assert_response :ok
    assert_equal "Ticket Field has been successfully deactivated.", json_body["notice"]
    assert_equal "Which browser you are using?", field.reload.agent_label
  end

  def test_that_update_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    field = create(
      :ticket_field,
      organization: @organization,
      agent_label: "Which browser you are using?")

    payload = {
      ticket_field: {
        agent_label: "Which computer you are using?",
        is_required: true,
        kind: "text",
        options: [],
        is_required_for_agent_when_closing_ticket: true
      }
    }
    put api_v1_desk_ticket_field_url(field, payload), headers: headers(@user)

    assert_response :forbidden
  end

  def test_that_ticket_field_is_not_updated_with_invalid_data
    field = create :ticket_field, organization: @organization

    payload = {
      ticket_field: {
        name: "Which computer you are using?",
        is_required: true,
        kind: "dropdown",
        ticket_field_options_attributes: []
      }
    }
    put api_v1_desk_ticket_field_url(field, payload), headers: headers(@user)

    assert_response :unprocessable_entity
  end

  def test_that_ticket_field_without_responses_is_hard_deleted
    field1 = create(:ticket_field, organization: @organization, state: "inactive")

    assert_difference "Desk::Ticket::Field.count", -1 do
      delete api_v1_desk_ticket_field_url(field1), headers: headers(@user)
    end
    assert_response :ok
    assert_raise ActiveRecord::RecordNotFound do
      field1.reload
    end
  end

  def test_that_delete_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    field1 = create(:ticket_field, organization: @organization, state: "inactive")

    delete api_v1_desk_ticket_field_url(field1), headers: headers(@user)
    assert_response :forbidden
  end

  def test_that_ticket_field_with_responses_is_soft_deleted
    field1 = create(:ticket_field, organization: @organization)
    create(:ticket_field_response, ticket_field: field1)

    assert_nil field1.reload.deleted_at

    assert_difference "Desk::Ticket::Field.count", -1 do
      delete api_v1_desk_ticket_field_url(field1), headers: headers(@user)
    end
    assert_response :ok

    assert_not_nil field1.reload.deleted_at
  end

  def test_that_active_ticket_field_cannot_be_deleted
    field = create(:ticket_field, state: "active", organization: @organization)

    delete api_v1_desk_ticket_field_url(field), headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Cannot delete active ticket field"
  end
end
