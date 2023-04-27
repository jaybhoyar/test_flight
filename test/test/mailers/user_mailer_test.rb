# frozen_string_literal: true

require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  def setup
    stub_request(:any, /fonts.googleapis.com/)
  end

  def test_blocked_user_mailer
    ethan = create :user
    ethan.deactivate!
    email = UserMailer
      .with(organization_name: ethan.organization.name)
      .blocked_email(ethan.first_name_or_email, ethan.email)
      .deliver_now

    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal ["notification.staging@neeto.com"], email.from
    assert_equal [ethan.email], email.to
    assert_equal ["notification.staging@neeto.com"], email.reply_to
    assert_includes email.subject, "Cannot create tickets with email #{ethan.email}"
  end
end
