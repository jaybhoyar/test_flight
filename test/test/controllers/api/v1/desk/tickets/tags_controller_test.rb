# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Tickets::TagsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)
    @manage_permission = Permission.find_or_create_by(name: "admin.manage_ticket_tags", category: "Admin")
    role = create :organization_role, permissions: [@manage_permission]
    @user.update(role:)
  end

  def test_create_success
    payload = { tag: { name: "Science" } }
    post api_v1_desk_tags_url(payload), headers: headers(@user)

    assert_response :ok
    assert_equal "Tag has been successfully created.", json_body["notice"]
    assert_equal "Science", json_body["tag"]["name"]
  end

  def test_that_create_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    payload = { tag: { name: "Science" } }
    post api_v1_desk_tags_url(payload), headers: headers(@user)

    assert_response :forbidden
  end

  def test_create_failure
    tag = create(:ticket_tag, name: "exampletag", organization: @organization)

    payload = { tag: { name: tag.name } }
    post api_v1_desk_tags_url(payload), headers: headers(@user)

    assert_response :unprocessable_entity
    assert_equal ["Name has already been taken"], json_body["errors"]
  end

  def test_index_default_order
    create_list(:ticket_tag, 2, organization: @organization)
    get api_v1_desk_tags_url, headers: headers(@user)
    tags = @organization.ticket_tags.order("created_at DESC")

    assert_response :ok
    assert_equal tags.count, json_body["tags"].count
    assert_equal tags[0].id, json_body["tags"][0]["id"]
  end

  def test_index_name_ASC_order
    create_list(:ticket_tag, 2, organization: @organization)
    payload = { column: "name", direction: "ASC" }
    get api_v1_desk_tags_url,
      headers: headers(@user),
      params: payload
    tags = @organization.ticket_tags.order("name ASC")

    assert_response :ok
    assert_equal tags.count, json_body["tags"].count
    assert_equal tags[0].id, json_body["tags"][0]["id"]
  end

  def test_all_tags_present
    create_list(:ticket_tag, 2, organization: @organization)
    payload = { column: "taggings_count", direction: "ASC" }
    get api_v1_desk_tags_url,
      headers: headers(@user),
      params: payload
    tags = @organization.ticket_tags.order("taggings_count ASC")

    assert_response :ok
    assert_equal tags.count, json_body["tags"].count
  end

  def test_ticket_tag_list_is_paginated
    create_list(:ticket_tag, 15, organization: @organization)
    ticket_tag_params = { page_index: 1, limit: 2 }

    get api_v1_desk_tags_url,
      headers: headers(@user),
      params: ticket_tag_params

    assert_response :ok
    assert_equal 2, json_body["tags"].size
    assert_equal 15, json_body["total_count"]
  end

  def test_update_tag_success
    tag = create(:ticket_tag, organization: @organization)
    edited_name = "refund-products"
    payload = { tag: { name: edited_name } }
    patch api_v1_desk_tag_url(tag.id),
      headers: headers(@user),
      params: payload
    tag.reload

    assert_response :ok
    assert_equal "Tag has been successfully updated.", json_body["notice"]
    assert_equal edited_name, json_body["tag"]["name"]
  end

  def test_that_update_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    tag = create(:ticket_tag, organization: @organization)
    patch api_v1_desk_tag_url(tag.id), headers: headers(@user), params: {}

    assert_response :forbidden
  end

  def test_update_tag_incorrect_tag
    edited_name = "refund-products"
    payload = { tag: { name: edited_name } }

    patch api_v1_desk_tag_url("sss"),
      headers: headers(@user),
      params: payload

    assert_response 404
  end

  def test_update_tag_failure
    tag = create(:ticket_tag, organization: @organization)
    edited_name = ""
    payload = { tag: { name: edited_name } }
    patch api_v1_desk_tag_url(tag.id),
      headers: headers(@user),
      params: payload

    assert_response 422
    assert_equal "Name can't be blank", json_body["errors"][0]
  end

  def test_search_substring_of_tag_name
    tag_names = ["and", "Land", "wand", "male", "dale", "pale", "test", "waste"]
    tag_names.each { |name| @organization.ticket_tags.create(name:) }
    payload = { search_string: "le" }
    get api_v1_desk_tags_url,
      headers: headers(@user),
      params: payload
    tags = @organization.ticket_tags.order("name ASC")

    assert_response :ok
    assert_equal 3, json_body["tags"].count
    assert_equal json_body["tags"][0]["name"], "pale"
    assert_equal ["dale", "male", "pale"], json_body["tags"].collect { |i| i["name"] }.sort
  end

  def test_ticket_count
    all_tags = create_list(:ticket_tag, 4, organization: @organization)
    assigned_tags = all_tags.first(2)
    ticket = create(:ticket, organization: @organization)

    ticket.update(tags: assigned_tags)

    get api_v1_desk_tags_url, params: { include_tickets_count: true }, headers: headers(@user)

    assert_response :ok
    json_body_assiged_tags = json_body["tags"].select { |tag| assigned_tags.pluck(:id).include? tag["id"] }
    assert_equal [1, 1], json_body_assiged_tags.map { |i| i["ticket_count"] }
  end

  def test_delete_tag_success
    create_multiple_tags
    payload = { tag: { ids: tags.map(&:id) } }

    assert_equal 5, tags.count

    delete destroy_multiple_api_v1_desk_tags_url(payload),
      headers: headers(@user)

    assert_response :ok
    assert_equal "Tags have been successfully deleted.", json_body["notice"]

    assert_equal 0, tags.count
  end

  def test_that_delete_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    create_multiple_tags
    payload = { tag: { ids: tags.map(&:id) } }

    delete destroy_multiple_api_v1_desk_tags_url(payload),
      headers: headers(@user)

    assert_response :forbidden
  end

  def test_update_merging_of_2_tags_successful
    setup_tickets_and_tags
    primary, secondry = @organization.ticket_tags.first(2)
    primary_tag_tickets_count = primary.tickets.count
    secondry_tag_tickets_count = secondry.tickets.count
    tag_params = { tags: { primary_id: primary.id, secondry_id: secondry.id } }

    patch merge_api_v1_desk_tags_url(@organization.api_key),
      headers: headers(@user),
      params: tag_params
    primary.reload
    assert_response :ok

    assert_nil @organization.ticket_tags.find_by(id: secondry.id)
    assert_equal primary.tickets.count, (primary_tag_tickets_count + secondry_tag_tickets_count)
  end

  def test_update_merging_of_2_tags_unsuccessful
    setup_tickets_and_tags
    primary = @organization.ticket_tags.first
    secondry = "dummy"
    primary_tag_tickets_count = primary.tickets.count
    tag_params = { tags: { primary_id: primary.id, secondry_id: secondry } }

    patch merge_api_v1_desk_tags_url(@organization.api_key),
      headers: headers(@user),
      params: tag_params

    assert_response :unprocessable_entity
    assert_equal ["Unable to find secondry tag with id: #{secondry}."], json_body["errors"]
  end

  private

    def setup_tickets_and_tags
      tags = create_list(:ticket_tag, 3, organization: @organization)
      tags.each do |tag|
        tickets = create_list(:ticket, 3, organization: @organization)
        tickets.each do |ticket|
          ticket.tags << tag
        end
      end
    end

    def create_multiple_tags
      5.times do
        create(:ticket_tag, organization: @organization)
      end
    end

    def tags
      @organization.ticket_tags.all.to_a
    end
end
