# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::TicketsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user, :agent
    @organization = @user.organization
    @ticket = create :ticket, organization: @organization,
      requester: create(:user, organization: @organization)

    create :ticket_field, agent_label: "Customer Name", organization: @organization
    create :ticket_field, agent_label: "Customer Age", organization: @organization
    create :comment, ticket: @ticket

    sign_in @user
    host! test_domain(@organization.subdomain)

    @desk_permission_1 = Permission.find_or_create_by(name: "desk.view_tickets", category: "Desk")
    @desk_permission_2 = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")
    @desk_permission_3 = Permission.find_or_create_by(name: "desk.manage_own_tickets", category: "Desk")
    role = create :organization_role, permissions: [@desk_permission_1, @desk_permission_2, @desk_permission_3]
    @user.update(role:)
  end

  # 1. Index
  def test_that_user_with_custom_role_and_permission_can_access_tickets_list
    role = create :organization_role, :user_defined, permissions: [@desk_permission_1]
    @user.update(role:)

    ticket_filter_params = { ticket: { first: "15", base_filter_by: "all" } }
    get api_v1_desk_tickets_url, params: ticket_filter_params, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["tickets"].size
  end

  def test_user_with_permissions_to_see_only_own_tickets
    role = create :organization_role, :user_defined, permissions: [@desk_permission_3]
    @user.update(role:)

    create :ticket, organization: @organization
    create :ticket, organization: @organization, agent: @user

    ticket_filter_params = { ticket: { first: "15", base_filter_by: "all" } }
    get api_v1_desk_tickets_url, params: ticket_filter_params, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["tickets"].size
  end

  def test_that_user_with_custom_role_without_permission_cannot_access_tickets_list
    role = create :organization_role, :user_defined

    @user.update(role:)

    ticket_filter_params = { ticket: { first: "15", base_filter_by: "all" } }
    get api_v1_desk_tickets_url, params: ticket_filter_params, headers: headers(@user)

    assert_response :forbidden
  end

  def test_index_success_without_filters
    ticket_filter_params = { ticket: { first: "15", base_filter_by: "all" } }
    get api_v1_desk_tickets_url,
      params: ticket_filter_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["tickets"].size
  end

  def test_index_is_paginated
    create_tickets

    ticket_filter_params = { ticket: { first: "15", base_filter_by: "all" }, page: 1, limit: 2 }
    get api_v1_desk_tickets_url,
      params: ticket_filter_params,
      headers: headers(@user)

    assert_response :ok

    assert_equal 2, json_body["tickets"].size
    assert_equal 6, json_body["total_count"]
  end

  def test_index_success_with_filters
    ticket_filter_params = { ticket: { filter_by: { "0" => { node: "status", rule: "is", value: "open" } } } }
    get api_v1_desk_tickets_url,
      params: ticket_filter_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["tickets"].size

    ticket_filter_params = { ticket: { filter_by: { "0" => { node: "category", rule: "is", value: "Questions" } } } }
    get api_v1_desk_tickets_url,
      params: ticket_filter_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal 0, json_body["tickets"].size
  end

  def test_index_success_with_sorting
    new_ticket = create(:ticket_for_feature_request, organization: @organization)
    ticket_sort_params = { ticket: { sort_by: { column: "priority", direction: "DESC" } } }
    get api_v1_desk_tickets_url,
      params: ticket_sort_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal json_body["tickets"].first["number"], new_ticket.number
  end

  def test_index_success_with_sorting_for_custom_view
    Thread.current[:organization] = @organization

    view = create(
      :view, title: Faker::Lorem.sentence, organization: @organization, sort_column: "priority",
      sort_direction: "DESC")
    view.rule.organization_id = view.organization_id
    view.save!
    view.reload

    create_tickets

    ticket_filter_params = { ticket: { base_filter_by: view.title, is_custom_view: "true" } }
    get api_v1_desk_tickets_url,
      params: ticket_filter_params,
      headers: headers(@user)

    assert_equal json_body["tickets"].first["id"],
      @organization.tickets.where("subject ILIKE ?", "%refund%").order("priority DESC").first[:id]
  end

  def test_ticket_index_with_default_filters
    ticket1 = create(
      :ticket, organization: @organization, status: Ticket::DEFAULT_STATUSES[:new],
      agent_id: create(:user).id)
    ticket2 = create(:ticket, organization: @organization)
    ticket2.update!(status: Ticket::DEFAULT_STATUSES[:spam])
    ticket3 = create(:ticket, organization: @organization)
    ticket3.update!(status: Ticket::DEFAULT_STATUSES[:trash])
    ticket4 = create(:ticket, organization: @organization, status: Ticket::DEFAULT_STATUSES[:new], agent_id: nil)
    ticket5 = create(:ticket, organization: @organization, status: Ticket::DEFAULT_STATUSES[:closed])

    ticket_filter_params = { ticket: { base_filter_by: "all" } }
    get api_v1_desk_tickets_url,
      params: ticket_filter_params,
      headers: headers(@user)

    assert_equal 3, json_body["tickets"].size

    ticket_filter_params = { ticket: { base_filter_by: "open" } }
    get api_v1_desk_tickets_url,
      params: ticket_filter_params,
      headers: headers(@user)

    assert_equal 3, json_body["tickets"].size

    ticket_filter_params = { ticket: { base_filter_by: "spam" } }
    get api_v1_desk_tickets_url,
      params: ticket_filter_params,
      headers: headers(@user)

    assert_equal 1, json_body["tickets"].size

    ticket_filter_params = { ticket: { base_filter_by: "assigned" } }

    get api_v1_desk_tickets_url,
      params: ticket_filter_params,
      headers: headers(@user)

    assert_equal 1, json_body["tickets"].size

    ticket_filter_params = { ticket: { base_filter_by: "closed" } }
    get api_v1_desk_tickets_url,
      params: ticket_filter_params,
      headers: headers(@user)

    assert_equal 1, json_body["tickets"].size

    ticket_filter_params = { ticket: { base_filter_by: "unassigned" } }
    get api_v1_desk_tickets_url,
      params: ticket_filter_params,
      headers: headers(@user)

    assert_equal 2, json_body["tickets"].size
  end

  def test_filtering_tickets_based_on_tag_ids
    ticket = create(:ticket, organization: @organization)
    tag = create(:ticket_tag, organization: @organization)
    ticket.update(tags: [tag])

    ticket_filter_params = {
      ticket: {
        filter_by: {
          "0" => { node: "taggings.tag_id", rule: "is", value: tag.id }
        },
        include_models: { "0" => { value: "taggings" } },
        base_filter_by: "unfiltered"
      }
    }
    get api_v1_desk_tickets_url,
      params: ticket_filter_params,
      headers: headers(@user)

    assert_equal 1, json_body["tickets"].count
    assert_equal ticket.id, json_body["tickets"][0]["id"]
  end

  def test_tickets_search_by_subject
    create_tickets

    ticket_params = {
      ticket: {
        sort_by: { column: "number", direction: "desc" },
        filter_by: {
          "0": {
            node: "keyword",
            rule: "contains", value: "unable to pay"
          }
        }
      }
    }

    get api_v1_desk_tickets_url, params: ticket_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal 2, json_body["tickets"].size
  end

  def test_tickets_search_by_number_starts_with_ignored_character
    ticket_params = {
      ticket: {
        sort_by: { column: "number", direction: "desc" },
        filter_by: {
          "0": {
            node: "keyword",
            rule: "contains", value: "##{@ticket.number}"
          }
        }
      }
    }

    get api_v1_desk_tickets_url, params: ticket_params, headers: headers(@user)

    assert_equal 1, json_body["tickets"].size
  end

  # 2. Show
  def test_that_user_with_custom_role_and_permission_can_access_ticket_details
    role = create :organization_role, :user_defined, permissions: [@desk_permission_1]

    @user.update(role:)

    get api_v1_desk_ticket_url(@ticket), headers: headers(@user)

    assert_response :ok
  end

  def test_that_user_with_custom_role_without_permission_cannot_access_ticket_details
    role = create :organization_role, :user_defined

    @user.update(role:)

    get api_v1_desk_ticket_url(@ticket), headers: headers(@user)

    assert_response :forbidden
  end

  def test_that_user_with_permissions_to_only_manage_own_tickets_cannot_access_other_tickets
    role = create :organization_role, :user_defined, permissions: [@desk_permission_3]
    @user.update(role:)

    get api_v1_desk_ticket_url(@ticket), headers: headers(@user)

    assert_response :forbidden
  end

  def test_show_success
    get api_v1_desk_ticket_url(@ticket.id), headers: headers(@user)

    assert_response :ok
    assert json_body["ticket"]
    assert_equal %w(
      activities category channel comments created_at description group
      id number user priority requester status subject
      survey_comment survey_response_slug survey_response_text tags tasks
      ticket_fields ticket_statuses
    ).sort, json_body["ticket"].keys.sort
    non_system_ticket_fields_count = @organization.ticket_fields.where(is_system: "false").count
    assert_equal non_system_ticket_fields_count, json_body["ticket"]["ticket_fields"].count
  end

  def test_show_response_has_parent_ticket
    task = @ticket.tasks.create(name: "Site installation", info: "Site installation service.")
    conversion_service = Desk::Tasks::ConvertToTicketService.new(task, @user)
    conversion_service.process
    converted_ticket = conversion_service.converted_ticket

    get api_v1_desk_ticket_url(converted_ticket.id), headers: headers(@user)

    assert_equal @ticket.id, json_body["ticket"]["parent_ticket"]["id"]
  end

  def test_show_failure
    get api_v1_desk_ticket_url(0), headers: headers(@user)

    assert_response :not_found
  end

  def test_should_get_ticket_by_number
    other_org_ticket = create :ticket, number: @ticket.number

    get api_v1_desk_ticket_url(@ticket.number), headers: headers(@user)

    assert_response :ok
    assert json_body["ticket"]
    assert_not_equal other_org_ticket.id, json_body["ticket"]["id"]
    assert_equal %w(
      activities category channel comments created_at description group
      id number user priority requester status subject
      survey_comment survey_response_slug survey_response_text tags tasks
      ticket_fields ticket_statuses
    ).sort, json_body["ticket"].keys.sort
    non_system_ticket_fields_count = @organization.ticket_fields.where(is_system: "false").count
    assert_equal non_system_ticket_fields_count, json_body["ticket"]["ticket_fields"].count
  end

  def test_that_not_found_is_returned_when_ticket_with_number_is_not_found
    get api_v1_desk_ticket_url(9999999), headers: headers(@user)

    assert_response :not_found
    assert_equal "Could not find the ticket.", json_body["error"]
  end

  def test_that_not_found_is_returned_when_ticket_with_id_is_not_found
    get api_v1_desk_ticket_url(SecureRandom.uuid), headers: headers(@user)

    assert_response :not_found
    assert_equal "Could not find the ticket.", json_body["error"]
  end

  # 3. Create
  def test_that_ticket_is_created
    assert_difference "::Ticket.count" do
      post api_v1_desk_tickets_url, params: create_ticket_payload, headers: headers(@user)
    end
    assert_response :ok
    assert_equal "Ticket has been successfully created.", json_body["notice"]
  end

  def test_that_user_with_manage_own_tickets_permissions_cannot_create_tickets
    role = create :organization_role, :user_defined, permissions: [@desk_permission_3]
    @user.update(role:)

    assert_no_difference "::Ticket.count" do
      post api_v1_desk_tickets_url, params: create_ticket_payload, headers: headers(@user)
    end
    assert_response :forbidden
  end

  def test_that_ticket_is_not_created_when_user_does_not_have_permissions
    role = create :organization_role, :user_defined, permissions: [@desk_permission_1]
    @user.update(role:)

    assert_no_difference "::Ticket.count" do
      post api_v1_desk_tickets_url, params: create_ticket_payload, headers: headers(@user)
    end

    assert_response :forbidden
  end

  def test_that_ticket_is_created_when_user_has_permissions
    role = create :organization_role, :user_defined, permissions: [@desk_permission_2]
    @user.update(role:)

    assert_difference "::Ticket.count" do
      post api_v1_desk_tickets_url, params: create_ticket_payload, headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Ticket has been successfully created.", json_body["notice"]
  end

  def test_that_ticket_is_created_with_attachments
    assert_difference ["Comment.joins(:attachments_attachments).count", "::Ticket.count"] do
      file = File.open(Rails.root.join("public", "apple-touch-icon.png"))
      attachments = [{ io: file, filename: "image.png", content_type: "image/png" }]
      payload = create_ticket_payload
      signed_id = do_fake_direct_upload

      payload[:ticket][:comments_attributes][:attachments] = [signed_id]

      post api_v1_desk_tickets_url, params: payload, headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Ticket has been successfully created.", json_body["notice"]
  end

  def test_that_create_ticket_fails_with_invalid_data
    invalid_ticket_create_payload = {
      ticket: { subject: "", comments_attributes: { info: "" } }
    }

    assert_no_difference "::Ticket.count" do
      post api_v1_desk_tickets_url, params: invalid_ticket_create_payload, headers: headers(@user)
    end
  end

  def test_create_ticket_success_when_comment_info_is_not_present
    ticket_create_payload = {
      ticket: { subject: "Test", comments_attributes: { info: "" } }
    }

    post api_v1_desk_tickets_url, params: ticket_create_payload, headers: headers(@user)

    assert_includes json_body["notice"], "Ticket has been successfully created."
  end

  def test_that_when_ticket_is_created_matching_rules_are_applied
    create_automation_rule("on_ticket_create")

    assert_difference ["::Ticket.count", "Desk::Automation::ExecutionLogEntry.count"] do
      Sidekiq::Testing.inline! do
        post api_v1_desk_tickets_url, params: create_ticket_payload, headers: headers(@user)
      end
    end

    assert_response :ok
    ticket = ::Ticket.find_by(subject: "Vintage table lamp - Out of stock?")
    assert_not_empty ticket.tags
    assert_equal "old", ticket.tags.first.name
  end

  def test_that_when_ticket_is_created_other_trigger_matching_rules_are_not_applied
    create_automation_rule(:on_reply_added)

    assert_no_difference ["Desk::Automation::ExecutionLogEntry.count"] do
      Sidekiq::Testing.inline! do
        post api_v1_desk_tickets_url, params: create_ticket_payload, headers: headers(@user)
      end
    end

    assert_response :ok
    ticket = ::Ticket.find_by(subject: "Vintage table lamp - Out of stock?")
    assert_empty ticket.tags
  end

  # 4. Update
  def test_that_update_ticket_works_when_user_has_permissions
    role = create :organization_role, :user_defined, permissions: [@desk_permission_2]
    @user.update(role:)

    create(:comment, ticket: @ticket)

    patch api_v1_desk_ticket_url(@ticket), params: update_ticket_payload, headers: headers(@user)

    @ticket.reload
    assert_response :ok
    assert_equal "Vintage table lamp - Out of stock?", @ticket.subject
    assert_equal "Is it out of stock or do you not sell those anymore?",
      @ticket.comments.in_order.first.info.to_plain_text
  end

  def test_that_update_ticket_fails_when_user_lacks_permissions
    role = create :organization_role, :user_defined, permissions: [@desk_permission_1]
    @user.update(role:)

    create(:comment, ticket: @ticket)

    patch api_v1_desk_ticket_url(@ticket),
      params: update_ticket_payload,
      headers: headers(@user)

    assert_response :forbidden
  end

  def test_that_user_with_manage_own_tickets_permissions_can_update_ticket
    role = create :organization_role, :user_defined, permissions: [@desk_permission_3]
    @user.update(role:)
    @ticket.update_column :agent_id, @user.id

    create(:comment, ticket: @ticket)

    patch api_v1_desk_ticket_url(@ticket), params: update_ticket_payload, headers: headers(@user)

    @ticket.reload
    assert_response :ok
    assert_equal "Vintage table lamp - Out of stock?", @ticket.subject
    assert_equal "Is it out of stock or do you not sell those anymore?",
      @ticket.comments.in_order.first.info.to_plain_text
  end

  def test_update_ticket_resolution_due_date_success
    create(:comment, ticket: @ticket)
    resolution_due_date = Time.zone.today
    resolution_due_date_update_params = {
      ticket: {
        resolution_due_date:
      }
    }

    put api_v1_desk_ticket_url(@ticket),
      params: resolution_due_date_update_params,
      headers: headers(@user)

    @ticket.reload
    assert_response :ok
    assert_equal resolution_due_date, @ticket.reload.resolution_due_date
  end

  def test_that_update_ticket_fails_with_invalid_data
    comment = create(:comment, ticket: @ticket)
    invalid_ticket_update_payload = {
      ticket: { subject: "", comments_attributes: { id: comment.id, info: "" } }
    }

    patch api_v1_desk_ticket_url(@ticket),
      params: invalid_ticket_update_payload,
      headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Comments info can't be blank"
  end

  def test_new_tag_creation
    create(:comment, ticket: @ticket)

    patch api_v1_desk_ticket_url(@ticket), params: new_tag_payload, headers: headers(@user)

    @ticket.reload
    assert_response :ok
    assert_equal 1, @ticket.tags.count
    assert_equal new_tag_payload[:ticket][:tags][0][:name], @ticket.tags.first.name
  end

  def test_that_when_ticket_is_updated_matching_rules_are_applied
    Sidekiq::Testing.inline!

    create_automation_rule(:on_ticket_update)

    assert_difference ["Desk::Automation::ExecutionLogEntry.count"] do
      patch api_v1_desk_ticket_url(@ticket), params: update_ticket_payload, headers: headers(@user)
    end

    assert_response :ok
    ticket = ::Ticket.find_by(subject: "Vintage table lamp - Out of stock?")
    assert_not_empty ticket.tags
    assert_equal "old", ticket.tags.first.name
  end

  def test_that_when_ticket_is_updated_other_trigger_matching_rules_are_not_applied
    Sidekiq::Testing.inline!

    create_automation_rule("on_ticket_create")

    assert_no_difference ["Desk::Automation::ExecutionLogEntry.count"] do
      patch api_v1_desk_ticket_url(@ticket), params: update_ticket_payload, headers: headers(@user)
    end

    assert_response :ok
    ticket = ::Ticket.find_by(subject: "Vintage table lamp - Out of stock?")
    assert_empty ticket.tags
  end

  # 5. Destroy
  def test_that_destroy_works_for_user_with_permissions
    role = create :organization_role, :user_defined, permissions: [@desk_permission_2]
    @user.update(role:)

    assert_difference "::Ticket.count", -1 do
      delete api_v1_desk_ticket_url(@ticket), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Ticket #{@ticket.number} has been successfully deleted.", json_body["notice"]
  end

  def test_that_destroy_fails_for_user_lacking_permissions
    role = create :organization_role, :user_defined, permissions: [@desk_permission_1]
    @user.update(role:)

    assert_no_difference "::Ticket.count" do
      delete api_v1_desk_ticket_url(@ticket), headers: headers(@user)
    end

    assert_response :forbidden
  end

  def test_that_destroy_does_not_work_for_invalid_ticket
    delete api_v1_desk_ticket_url(0), headers: headers(@user)

    assert_response :not_found
  end

  # Update multiple
  def test_that_ticket_multiple_update_works_for_user_with_permissions
    role = create :organization_role, :user_defined, permissions: [@desk_permission_2]
    @user.update(role:)

    create_multiple_tickets

    payload = { ticket: { ids: tickets.map(&:id), status: "trash" } }

    assert_equal 6, tickets.count
    assert_equal 0, trashed_tickets_count

    patch update_multiple_api_v1_desk_tickets_url(payload),
      headers: headers(@user)

    assert_response :ok
    assert_equal "Tickets have been successfully moved to trash.", json_body["notice"]
    assert_equal 6, trashed_tickets_count
  end

  def test_that_ticket_multiple_update_does_not_work_for_user_without_permissions
    role = create :organization_role, :user_defined, permissions: [@desk_permission_1]
    @user.update(role:)

    create_multiple_tickets

    payload = { ticket: { ids: tickets.map(&:id), status: "trash" } }

    assert_equal 6, tickets.count
    assert_equal 0, trashed_tickets_count

    patch update_multiple_api_v1_desk_tickets_url(payload),
      headers: headers(@user)

    assert_response :forbidden
  end

  def test_ticket_multiple_spam
    create_multiple_tickets

    payload = { ticket: { ids: tickets.map(&:id), status: "spam" } }

    assert_equal 6, tickets.count
    assert_equal 0, trashed_tickets_count

    patch update_multiple_api_v1_desk_tickets_url(payload),
      headers: headers(@user)

    assert_response :ok
    assert_equal "Tickets have been successfully marked as spam.", json_body["notice"]
    assert_equal 6, @organization.tickets.where(status: "spam").count
  end

  def test_update_ticket_multiple_agent
    create_multiple_tickets

    john = create :user, organization: @organization, first_name: "John"
    payload = { ticket: { ids: tickets.map(&:id), agent_id: john.id } }

    assert_equal 0, ::Ticket.where(agent_id: john.id).count

    patch update_multiple_api_v1_desk_tickets_url(payload),
      headers: headers(@user)

    assert_response :ok
    assert_equal "Tickets have been successfully updated.", json_body["notice"]
    assert_equal 6, ::Ticket.where(agent_id: john.id).count
  end

  def test_that_ticket_is_closed_if_the_responses_are_recorded
    field = create :ticket_field, agent_label: "Customer Last Name", is_required_for_agent_when_closing_ticket: true,
      organization: @organization
    create :ticket_field_response, ticket_field: field, owner: @ticket

    close_ticket_params = { ticket: { status: "closed" } }

    patch api_v1_desk_ticket_url(@ticket), params: close_ticket_params, headers: headers(@user)
    assert_response :ok
    assert_equal "closed", @ticket.reload.status
  end

  def test_that_ticket_is_not_closed_if_not_verified_by_ticket_field_conditions
    create :ticket_field, agent_label: "Customer Last Name", is_required_for_agent_when_closing_ticket: true,
      organization: @organization
    close_ticket_params = { ticket: { status: "closed" } }

    patch api_v1_desk_ticket_url(@ticket), params: close_ticket_params, headers: headers(@user)
    assert_response :unprocessable_entity
    assert_equal "open", @ticket.reload.status
    assert_includes json_body["errors"], "Customer Last Name is required to close the ticket."
  end

  def test_that_ticket_is_not_closed_if_the_responses_are_not_recorded
    ticket = create :ticket, organization: @organization
    field = create :ticket_field, agent_label: "Customer Last Name", is_required_for_agent_when_closing_ticket: true,
      organization: @organization
    create :ticket_field_response, ticket_field: field, owner: ticket

    close_ticket_params = { ticket: { status: "closed" } }

    patch api_v1_desk_ticket_url(@ticket), params: close_ticket_params, headers: headers(@user)
    assert_response :unprocessable_entity
    assert_equal "open", @ticket.reload.status
    assert_includes json_body["errors"], "Customer Last Name is required to close the ticket."
  end

  def test_that_ticket_is_not_closed_if_the_required_checkbox_field_is_unchecked
    field = create :ticket_field, kind: :checkbox, agent_label: "Are you human?",
      is_required_for_agent_when_closing_ticket: true, organization: @organization
    create :ticket_field_response, ticket_field: field, owner: @ticket, value: false

    close_ticket_params = { ticket: { status: "closed" } }

    patch api_v1_desk_ticket_url(@ticket), params: close_ticket_params, headers: headers(@user)
    assert_equal "open", @ticket.reload.status
    assert_includes json_body["errors"], "Are you human? is required to close the ticket."
  end

  private

    def create_ticket_payload
      {
        ticket: {
          subject: "Vintage table lamp - Out of stock?",
          priority: "high",
          category: "None",
          customer_email: "matt@example.com",
          comments_attributes: {
            info: "I can’t find Vintage table lamp on site anymore. Is it out of stock or do you not sell those anymore?"
          }
        }
      }
    end

    def update_ticket_payload
      {
        ticket: {
          subject: "Vintage table lamp - Out of stock?",
          priority: "low",
          comments_attributes: {
            id: @ticket.comments.in_order.first.id,
            info: "Is it out of stock or do you not sell those anymore?"
          }
        }
      }
    end

    def new_tag_payload
      {
        ticket: {
          subject: "Vintage table lamp - Out of stock?",
          priority: "low",
          comments_attributes: {
            id: @ticket.comments.in_order.first.id,
            info: "Is it out of stock or do you not sell those anymore?"
          },
          tags: [{
            name: "test"
          }]
        }
      }
    end

    def create_automation_rule(execute)
      tag = create :ticket_tag, name: "old", organization: @organization
      if execute != "on_ticket_create"
        refund_rule = create :automation_rule, execute,
          name: "Assign tag old when subject contains Vintage",
          organization: @organization
      else
        refund_rule = create :automation_rule, :on_ticket_create,
          name: "Assign tag old when subject contains Vintage",
          organization: @organization
      end
      group = create :automation_condition_group, rule: refund_rule
      create :automation_condition_subject_contains_refund, conditionable: group, value: "vintage"
      create :automation_action, rule: refund_rule, name: "set_tags", tag_ids: [tag.id], status: nil
    end

    def do_fake_direct_upload
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("random text"), filename: "random.txt")
      blob.signed_id
    end

    def create_multiple_tickets
      5.times do
        create :ticket, organization: @organization, requester: create(:user)
      end
    end

    def tickets
      @organization.tickets.all
    end

    def trashed_tickets_count
      @organization.tickets.where(status: "trash").count
    end

    def create_tickets
      create(
        :ticket,
        organization: @organization,
        requester: @user,
        agent: @user,
        subject: "Unable to pay via stripe",
        category: "Questions",
        number: 2,
        priority: 0,
        status: "new",
        created_at: Date.current - 2.day,
        comments: [create(:comment)])

      create(
        :ticket,
        organization: @organization,
        requester: @user,
        agent: @user,
        subject: "Unable to pay, no payment button visible",
        category: "Incident",
        priority: 3,
        status: "on_hold",
        number: 3,
        created_at: Date.current - 1.day,
        comments: [create(:comment)])

      create(
        :ticket,
        organization: @organization,
        requester: @user,
        agent: @user,
        subject: "Unable to login",
        category: "Problem",
        priority: 1,
        status: "open",
        number: 4,
        created_at: Date.current + 1.month,
        comments: [create(:comment)])

      create(
        :ticket,
        organization: @organization,
        requester: @user,
        agent: @user,
        subject: "Query about refund",
        category: "Refund",
        priority: 3,
        status: "on_hold",
        number: 5,
        created_at: Date.current + 1.month,
        comments: [create(:comment)])

      create(
        :ticket,
        organization: @organization,
        requester: @user,
        agent: @user,
        subject: "Process to get a refund",
        category: "Refund",
        priority: 2,
        status: "on_hold",
        number: 6,
        created_at: Date.current + 1.month,
        comments: [create(:comment)])
    end
end
