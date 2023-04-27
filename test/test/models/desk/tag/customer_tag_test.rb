# frozen_string_literal: true

require "test_helper"

class Desk::Tag::CustomerTagTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization

    @customer_tag_params = {
      name: "VIP Customer",
      organization: @organization
    }
  end

  test "name should not be blank" do
    tag = @organization.customer_tags.new

    assert_not tag.valid?
    assert tag.errors.added?(:name, "can't be blank")
  end

  test "organization_id should not be blank" do
    tag = Desk::Tag::CustomerTag.new(name: "test")

    assert_not tag.valid?
    assert tag.errors.added?(:organization_id, "can't be blank")
  end

  test "should create record for valid data" do
    tag = @organization.customer_tags.new(name: "test")

    assert tag.save
  end

  test "should not create record for duplicate tag name case insensitve" do
    tag = @organization.customer_tags.new(name: "test")
    assert tag.save

    tag = @organization.customer_tags.new(name: "Test")
    assert_not tag.save
  end

  test "should return filtered records based on query string" do
    NAMES = ["Defective-products", "return-defective", "return-size", "return-customer-damaged"]
    NAMES.each { |name| @organization.customer_tags.create(name:) }
    filter_text = "DeFective"
    filtered_tags = Desk::Tag::CustomerTag.filter_by_name(filter_text)
    assert_equal ["Defective-products", "return-defective"], filtered_tags.pluck(:name).sort
  end

  test "for organization scope returns the tags for the organization" do
    create :customer_tag
    customer_tag = create :customer_tag, @customer_tag_params

    assert_equal 2, Desk::Tag::CustomerTag.count
    assert_equal 1, @organization.customer_tags.count
    assert_equal customer_tag.reload.id, @organization.customer_tags.first.id
  end

  test "organization must be present" do
    @customer_tag_params[:organization] = nil
    customer_tag = build :customer_tag, @customer_tag_params

    assert_not customer_tag.valid?
    assert_equal ["must exist"], customer_tag.errors[:organization]
  end

  test "can store same named tags for different organizations" do
    assert_difference "Desk::Tag::CustomerTag.count", 2 do
      create :customer_tag, name: "VIP", organization: @organization
      create :customer_tag, name: "VIP"
    end
  end

  test "tag name is stripped of whitespaces before validating" do
    customer_tag1 = create(:customer_tag, organization: @organization)
    customer_tag2 = build :customer_tag,
      name: "   " + customer_tag1.name + "   ",
      organization: @organization

    assert_raises ActiveRecord::RecordInvalid do
      customer_tag2.save!
    end
    assert_includes customer_tag2.errors.full_messages, "Name has already been taken"
  end
end
