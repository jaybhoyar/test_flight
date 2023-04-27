# frozen_string_literal: true

require "test_helper"

class EmailConfigurationTest < ActiveSupport::TestCase
  def test_valid_email_configuration
    email_configuration = create :email_configuration, email: "support"

    assert email_configuration.valid?
    assert_equal "support", email_configuration.email
    assert email_configuration.forward_to_email.start_with? "support."
    assert email_configuration.reply_to_email.start_with? "support."
  end

  def test_that_email_is_valid
    email_configuration = build :email_configuration, email: "_support"

    assert_not email_configuration.valid?
    assert_equal \
      "Email must be alphanumeric, may include period, hyphen or underscore and must not start/end with special characters.",
      email_configuration.errors.full_messages.first
  end

  def test_that_email_is_not_valid
    email_configuration = build :email_configuration, email: "s"

    assert_not email_configuration.valid?
    assert_equal "Email is too short (minimum is 2 characters)", email_configuration.errors.full_messages.first
  end

  def test_invalid_email_configuration
    invalid_email_config = EmailConfiguration.new

    assert_not invalid_email_config.valid?
    assert_includes invalid_email_config.errors.full_messages, "Organization must exist"
    assert_includes invalid_email_config.errors.full_messages, "Email can't be blank"
  end

  def test_empty_custom_name_for_custom_from_name
    organization = create(:organization)
    email_configuration = EmailConfiguration.create(
      email: "abc@gmail.com",
      from_name: "custom_name",
      organization:
    )
    assert_includes email_configuration.errors.full_messages, "Custom name can't be blank"
  end

  def test_from_name_value_default
    email_configuration = create(:email_configuration)
    assert_equal email_configuration.organization.name, email_configuration.from_name_value
  end

  def test_from_name_custom
    email_configuration = create(:email_configuration, from_name: "custom_name", custom_name: "Matrix")
    assert_equal "Matrix", email_configuration.from_name_value
  end

  def test_reply_to_email_default
    email_configuration = create(:email_configuration)
    assert_equal email_configuration.forward_to_email, email_configuration.reply_to_email
  end

  def test_reply_to_email_custom
    email_configuration = create(:email_configuration, reply_to_email: "neo@matrix.com")
    assert_equal "neo@matrix.com", email_configuration.reply_to_email
  end

  def test_form_name_as_organization_name
    organization = create(:organization)
    email_configuration = create(:email_configuration)
    assert_equal organization.name, email_configuration.from_name_value
  end

  def test_from_organization_name
    email_configuration = create(:email_configuration, email: "neo", from_name: "organization_name")
    assert_equal \
      "#{email_configuration.organization.name} <neo#{email_configuration.email_domain_suffix}>",
      email_configuration.from
  end

  def test_from_custom_name
    email_configuration = create(:email_configuration, email: "neo", from_name: "custom_name", custom_name: "Matrix")
    assert_equal "Matrix <neo#{email_configuration.email_domain_suffix}>", email_configuration.from
  end

  def test_from_agent_name
    user = create :user, first_name: "Ethan", last_name: "Hunt"
    email_configuration = create :email_configuration,
      email: "neo",
      from_name: "agent_name",
      organization: user.organization

    assert_equal \
      "Ethan Hunt <neo#{user.organization.email_domain_suffix}>",
      email_configuration.from(agent: user)
  end

  def test_from_agent_name_without_passing_the_agent
    user = create :user, first_name: "Ethan", last_name: "Hunt"
    email_configuration = create :email_configuration,
      email: "neo",
      from_name: "agent_name",
      organization: user.organization

    assert_equal "neo#{user.organization.email_domain_suffix}", email_configuration.from
  end
end
