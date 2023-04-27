# frozen_string_literal: true

require "test_helper"
class Desk::Tags::MergeServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    create_list(:ticket_tag, 3, organization: @organization)
  end

  def test_merge_2_valid_tags
    setup_tickets_and_tags
    primary, secondry = @organization.tags.first(2)
    primary_tag_tickets_count = primary.tickets.count
    secondry_tag_tickets_count = secondry.tickets.count
    tag_params = { primary_id: primary.id, secondry_id: secondry.id }
    merge_service = Desk::Tags::MergeService.new(@organization, tag_params)

    assert_empty merge_service.errors

    merge_service.merge
    primary.reload

    assert_nil @organization.tags.find_by(id: secondry.id)
    assert_equal primary.tickets.count, (primary_tag_tickets_count + secondry_tag_tickets_count)
  end

  def test_merge_of_invalid_secondry_tags
    primary = @organization.tags.first
    secondry = "dummy"
    tag_params = { primary_id: primary.id, secondry_id: secondry }
    merge_service = Desk::Tags::MergeService.new(@organization, tag_params)

    assert_equal merge_service.errors, ["Unable to find secondry tag with id: #{secondry}."]
    assert_equal merge_service.merge, false
  end

  def test_merge_of_invalid_primary_tags
    primary = "dummy"
    secondry = @organization.tags.first
    tag_params = { primary_id: primary, secondry_id: secondry.id }
    merge_service = Desk::Tags::MergeService.new(@organization, tag_params)

    assert_equal merge_service.errors, ["Unable to find primary tag with id: #{primary}."]
    assert_equal merge_service.merge, false
  end

  private

    def setup_tickets_and_tags
      tags = @organization.tags
      tags.each do |tag|
        tickets = create_list(:ticket, 3, organization: @organization)
        tickets.each do |ticket|
          ticket.tags << tag
        end
      end
    end
end
