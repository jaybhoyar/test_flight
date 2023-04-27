# frozen_string_literal: true

require "test_helper"

class OrganizationMailerTest < ActionMailer::TestCase
  def setup
    stub_request(:any, /fonts.googleapis.com/)
  end

  def test_organization_mailer
    ethan = create :user
    email = OrganizationMailer
      .with(organization_name: "")
      .missing_email([ethan.email], "invalid.invalidorg@neetoticket.com")
      .deliver_now

    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal ["notification.staging@neeto.com"], email.from
    assert_equal [ethan.email], email.to
    assert_equal ["notification.staging@neeto.com"], email.reply_to
    assert_includes email.subject, "Email invalid.invalidorg@neetoticket.com does not belong to anyone"
  end
end
