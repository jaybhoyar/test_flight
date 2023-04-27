# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Customers::TagsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)
    @manage_permission = Permission.find_or_create_by(name: "admin.manage_customer_tags", category: "Admin")
    role = create :organization_role, permissions: [@manage_permission]
    @user.update(role:)
  end

  def test_create_success
    payload = { tag: { name: "Science" } }
    post api_v1_desk_customers_tags_url(payload), headers: headers(@user)

    assert_response :ok
    assert_equal "Tag has been successfully created.", json_body["notice"]
    assert_equal "Science", json_body["tag"]["name"]
  end

  def test_that_create_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    payload = { tag: { name: "Science" } }
    post api_v1_desk_customers_tags_url(payload), headers: headers(@user)

    assert_response :forbidden
  end

  def test_create_failure
    tag = create(:customer_tag, organization: @organization)

    payload = { tag: { name: tag.name } }
    post api_v1_desk_customers_tags_url(payload), headers: headers(@user)

    assert_response :unprocessable_entity
    assert_equal ["Name has already been taken"], json_body["errors"]
  end

  def test_index_default_order
    create_list(:customer_tag, 2, organization: @organization)
    get api_v1_desk_customers_tags_url, headers: headers(@user)
    tags = @organization.customer_tags.order("created_at DESC")

    assert_response :ok
    assert_equal tags.count, json_body["tags"].count
    assert_equal tags[0].id, json_body["tags"][0]["id"]
  end

  def test_index_name_ASC_order
    create_list(:customer_tag, 2, organization: @organization)
    payload = { column: "name", direction: "ASC" }
    get api_v1_desk_customers_tags_url,
      headers: headers(@user),
      params: payload
    tags = @organization.customer_tags.order("name ASC")

    assert_response :ok
    assert_equal tags.count, json_body["tags"].count
    assert_equal tags[0].id, json_body["tags"][0]["id"]
  end

  def test_update_tag_success
    tag = create(:customer_tag, organization: @organization)

    edited_name = "refund-products"
    payload = { tag: { name: edited_name } }
    patch api_v1_desk_customers_tag_url(tag.id),
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

    tag = create(:customer_tag, organization: @organization)
    patch api_v1_desk_customers_tag_url(tag.id), headers: headers(@user), params: {}

    assert_response :forbidden
  end

  def test_update_tag_incorrect_tag
    edited_name = "refund-products"
    payload = { tag: { name: edited_name } }

    patch api_v1_desk_customers_tag_url("sss"),
      headers: headers(@user),
      params: payload

    assert_response 404
  end

  def test_update_tag_failure
    tag = create(:customer_tag, organization: @organization)
    edited_name = ""
    payload = { tag: { name: edited_name } }
    patch api_v1_desk_customers_tag_url(tag.id),
      headers: headers(@user),
      params: payload

    assert_response 422
    assert_equal "Name can't be blank", json_body["errors"][0]
  end

  def test_search_substring_of_tag_name
    tag_names = ["and", "Land", "wand", "male", "dale", "pale", "test", "waste"]
    tag_names.each { |name| @organization.customer_tags.create(name:) }
    payload = { search_string: "le" }
    get api_v1_desk_customers_tags_url,
      headers: headers(@user),
      params: payload
    tags = @organization.customer_tags.order("name ASC")

    assert_response :ok
    assert_equal 3, json_body["tags"].count
    assert_equal json_body["tags"][0]["name"], "pale"
    assert_equal ["dale", "male", "pale"], json_body["tags"].collect { |i| i["name"] }.sort
  end

  def test_customer_count
    all_tags = create_list(:customer_tag, 4, organization: @organization)
    assigned_tags = all_tags.first(2)
    customer = create(:customer_detail, user: @user)
    customer.update(tags: assigned_tags)

    get api_v1_desk_customers_tags_url,
      headers: headers(@user)

    assert_response :ok
    json_body_assiged_tags = json_body["tags"].select { |tag| assigned_tags.pluck(:id).include? tag["id"] }
    assert_equal [1, 1], json_body_assiged_tags.map { |i| i["customer_count"] }
  end

  def test_delete_tag_success
    create_multiple_tags
    payload = { tag: { ids: tags.map(&:id) } }

    assert_equal 5, tags.count

    delete destroy_multiple_api_v1_desk_customers_tags_url(payload),
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

    delete destroy_multiple_api_v1_desk_customers_tags_url(payload),
      headers: headers(@user)

    assert_response :forbidden
  end

  private

    def setup_customers_and_tags
      tags = create_list(:customer_tag, 3, organization: @organization)
      tags.each do |tag|
        customers = create_list(:customer_detail, 3, user: @user)
        customers.each do |customer|
          customer.customer_tags << tag
        end
      end
    end

    def create_multiple_tags
      5.times do
        create(:customer_tag, organization: @organization)
      end
    end

    def tags
      @organization.customer_tags.all.to_a
    end
end
