# frozen_string_literal: true

require "test_helper"

class AttachmentServiceTest < ActiveSupport::TestCase
  def setup
    ticket = create(:ticket_with_email_config, organization: create(:organization), requester: create(:user))
    @comment = create(:comment, :with_attachments, ticket:)
  end

  def test_attachment_service_behavior
    service = AttachmentService.new(@comment.attachments.first)

    assert service.path
    assert service.is_image
    assert "jpg", service.extension
  end
end
