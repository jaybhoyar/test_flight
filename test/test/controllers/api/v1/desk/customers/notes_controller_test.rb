# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Customers::NotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = create(:organization)
    @customer = create(:user, organization: @organization, role: nil)
    @user = create(:user, organization: @organization)

    sign_in(@user)
    host! test_domain(@organization.subdomain)

    @view_permission = Permission.find_or_create_by(name: "customer.view_customer_details", category: "Customer")
    @manage_permission = Permission.find_or_create_by(name: "customer.manage_customer_details", category: "Customer")
    role = create :organization_role, permissions: [@view_permission, @manage_permission]
    @user.update(role:)
  end

  def test_should_create_successfully
    payload = { notes: { description: "There is some issue with operations." } }
    post api_v1_desk_customer_notes_url(@user.id),
      params: payload,
      headers: headers(@user)
    assert_response :success

    note = @user.notes.order(:created_at).last

    assert_equal "There is some issue with operations.", note.description
  end

  def test_that_create_doesnt_work_without_permissions
    role = create :organization_role, permissions: [@view_permission]
    @user.update(role:)

    payload = { notes: { description: "There is some issue with operations." } }
    post api_v1_desk_customer_notes_url(@user.id),
      params: payload,
      headers: headers(@user)
    assert_response :forbidden
  end

  def test_should_not_create_for_blank_description
    payload = { notes: { description: "" } }

    post api_v1_desk_customer_notes_url(@user.id),
      params: payload,
      headers: headers(@user)

    assert_response 422
    assert_equal "Description can't be blank", json_body["errors"][0]
  end

  def test_should_not_update_for_blank_description
    note = create(:note, customer_id: @customer.id, agent_id: @user.id)
    payload = { notes: { description: "" } }

    put api_v1_desk_customer_note_url(@customer.id, note),
      params: payload,
      headers: headers(@user)

    assert_response 422
    assert_equal "Description can't be blank", json_body["errors"][0]
  end

  def test_should_update_successfully
    note = create(:note, customer_id: @customer.id, agent_id: @user.id)
    payload = { notes: { description: "There is some issue with the operations" } }

    put api_v1_desk_customer_note_url(@customer.id, note),
      params: payload,
      headers: headers(@user)

    assert_response :ok

    note.reload

    assert_equal "There is some issue with the operations", note.description
  end

  def test_that_update_doesnt_work_without_permissions
    role = create :organization_role, permissions: [@view_permission]
    @user.update(role:)

    note = create(:note, customer_id: @customer.id, agent_id: @user.id)
    payload = { notes: { description: "There is some issue with the operations" } }

    put api_v1_desk_customer_note_url(@customer.id, note),
      params: payload,
      headers: headers(@user)

    assert_response :forbidden
  end

  def test_should_return_all_records_for_customer_notes
    note = create(:note, customer_id: @customer.id, agent_id: @user.id)
    get api_v1_desk_customer_notes_url(@customer.id), headers: headers(@user)

    assert_response :ok

    assert json_body["notes"]
    assert_equal 1, json_body["notes"].count
  end

  def test_index_is_not_accessible_without_permissions
    role = create :organization_role
    @user.update(role:)

    note = create(:note, customer_id: @customer.id, agent_id: @user.id)
    get api_v1_desk_customer_notes_url(@customer.id), headers: headers(@user)

    assert_response :forbidden
  end

  def test_should_destroy_note
    note = create(:note, customer_id: @customer.id, agent_id: @user.id)
    delete api_v1_desk_customer_note_url(@customer.id, note.id), headers: headers(@user)

    assert_response :ok
    assert_equal 0, @customer.notes.count
  end

  def test_that_destroy_doesnt_work_without_permissions
    role = create :organization_role, permissions: [@view_permission]
    @user.update(role:)

    note = create(:note, customer_id: @customer.id, agent_id: @user.id)
    delete api_v1_desk_customer_note_url(@customer.id, note.id), headers: headers(@user)

    assert_response :forbidden
  end

  def test_should_not_destroy_invalid_note
    delete api_v1_desk_customer_note_url(@customer.id, "aaa"), headers: headers(@user)

    assert_response :not_found
  end

  def test_should_not_destroy_note_for_invalid_customer
    note = create(:note, customer_id: @customer.id, agent_id: @user.id)
    delete api_v1_desk_customer_note_url("sssss", note.id), headers: headers(@user)

    assert_response :not_found
  end
end
