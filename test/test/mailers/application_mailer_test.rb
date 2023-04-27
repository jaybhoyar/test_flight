# frozen_string_literal: true

require "test_helper"

class ApplicationMailerTest < ActionMailer::TestCase
  setup do
    stub_request(:any, /fonts.googleapis.com/)

    class MyTestMailer < ApplicationMailer
      def welcome
        mail(subject: "test", body: "test", to: "sheldon@bbt.com")
      end
    end
  end

  def test_email_configuration_default
    @email = MyTestMailer.with(organization_name: "BigBinary").welcome.deliver_now

    assert_equal "neetoDesk <notification.staging@neeto.com>", @email.header["From"].value
    assert_equal "notification.staging@neeto.com", @email.header["Reply-To"].value
    assert_equal "[BigBinary TEST] test", @email.subject
  end

  def test_email_configuration_current_organization
    Organization.current = create(:email_config_spinkart).organization
    @email = MyTestMailer.with(organization_name: "BigBinary").welcome.deliver_now

    assert_equal "neetoDesk <notification.staging@neeto.com>", @email.header["From"].value
    assert_equal "notification.staging@neeto.com", @email.header["Reply-To"].value
    assert_equal "[BigBinary TEST] test", @email.subject
  end
end
