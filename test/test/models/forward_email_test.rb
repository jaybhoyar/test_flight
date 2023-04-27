# frozen_string_literal: true

require "test_helper"

class ForwardEmailTest < ActiveSupport::TestCase
  def setup
    @comment = create(:comment)
  end

  def test_fails_for_blank_email
    forward_email = ForwardEmail.new(email: "jake@blank.com")

    assert_not forward_email.valid?
    assert_includes forward_email.errors.full_messages, "Comment must exist"
  end

  def test_fails_for_blank_comment_id
    forward_email = ForwardEmail.new(email: "jake@space.com", comment_id: "")

    assert_not forward_email.valid?
    assert_includes forward_email.errors.full_messages, "Comment must exist"
  end

  def test_create_forward_email_success
    forward_email = ForwardEmail.new(email: "jake@damon.com", comment_id: @comment.id)

    assert forward_email.valid?
    assert forward_email.save
  end
end
