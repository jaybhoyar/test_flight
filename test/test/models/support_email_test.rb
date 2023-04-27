# frozen_string_literal: true

require "test_helper"

class SupportEmailTest < ActiveSupport::TestCase
  def setup
    @email_configuration = create(:email_configuration)
    @organization = @email_configuration.organization
    @from_email = "mikel@test.lindsaar.net"
    @subject = "Unable to generate Invoice"
    @email_body = "<p>I am not able to generate an invoice for June 2019.</p><p>Please help.</p>Mike"

    @mail = Mail.new
    @mail.from = @from_email
    @mail.to = @email_configuration.forward_to_email
    @mail.subject = @subject
    @mail.body = @email_body

    @support_email = SupportEmail.new(@mail)
  end

  def test_organization
    assert_equal @organization, @support_email.organization
  end

  def test_from_new_user
    assert_difference "User.count", 1 do
      assert @support_email.from_user.is_a?(User)
      assert_equal @organization, @support_email.from_user.organization
      assert_equal @from_email, @support_email.from_user.email
    end
  end

  def test_belongs_to_an_organization?
    assert @support_email.belongs_to_an_organization?
  end

  def test_original_content
    assert_equal @email_body, @support_email.original_content
  end

  def test_sanitized_content
    assert_equal @email_body, @support_email.sanitized_content
  end
end
