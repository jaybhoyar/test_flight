# frozen_string_literal: true

require "test_helper"

class Desk::Tag::TicketTagTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
  end

  test "name should not be blank" do
    tag = @organization.ticket_tags.new

    assert_not tag.valid?
    assert tag.errors.added?(:name, "can't be blank")
  end

  test "organization_id should not be blank" do
    tag = Desk::Tag::TicketTag.new(name: "test")

    assert_not tag.valid?
    assert tag.errors.added?(:organization_id, "can't be blank")
  end

  test "should create record for valid data" do
    tag = @organization.ticket_tags.new(name: "test")

    assert tag.save
  end

  test "should not create record for duplicate tag name case insensitve" do
    tag = @organization.ticket_tags.new(name: "test")
    assert tag.save

    tag = @organization.ticket_tags.new(name: "Test")
    assert_not tag.save
  end

  test "should return filtered records based on query string" do
    NAMES = ["Defective-products", "return-defective", "return-size", "return-customer-damaged"]
    NAMES.each { |name| @organization.ticket_tags.create(name:) }
    filter_text = "DeFective"
    filtered_tags = Desk::Tag::TicketTag.filter_by_name(filter_text)
    assert_equal ["Defective-products", "return-defective"], filtered_tags.pluck(:name).sort
  end
end
