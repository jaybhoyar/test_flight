# frozen_string_literal: true

require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  def test_valid_organization
    organization = create(:organization)

    assert organization.valid?
  end

  def test_that_active_and_enabled_returns_correct_organizations
    active_organization = create(:organization)

    deleted_organization = create(:organization, enabled: false, cancelled_at: DateTime.now)

    disabled_organization = create(:organization, enabled: false)

    assert_equal 1, Organization.active.count
    assert_equal [active_organization], Organization.active.to_a
  end

  def test_that_old_subdomain_cache_is_cleared_after_update
    create :organization, subdomain: "bigbinary", name: "BigBinary"

    with_caching do
      bigbinary = cached_data_with_subdomain("bigbinary")
      assert_equal "BigBinary", bigbinary.name

      bigbinary.update(name: "TinyBinary")
      bigbinary = cached_data_with_subdomain("bigbinary")
      assert_equal "TinyBinary", bigbinary.name

      bigbinary.update(subdomain: "tinybinary")
      tinybinary = cached_data_with_subdomain("tinybinary")

      assert_equal "tinybinary", tinybinary.subdomain
      assert_nil cached_data_with_subdomain("bigbinary")
    end
  end

  def test_that_organization_is_incinerated
    organization = create :organization, subdomain: "bigbinary", name: "BigBinary"
    business_hour = create :business_hour, organization: organization
    default_survey = create :default_survey, organization: organization
    outbound_message_rule = create :outbound_message_rule, organization: organization
    question = create :default_question, survey: default_survey
    scale_choice = create :default_question_scale_choice_1, question: question
    agent = create :user, organization: organization
    group = create :group, organization: organization, business_hour: business_hour
    ticket = create :ticket, :with_desc, organization: organization, agent: agent, requester: agent, group: group

    create :automation_rule, organization: organization
    create :desk_macro_rule, organization: organization
    create :company, organization: organization
    create :organization_role, organization: organization
    create :slack_team, organization: organization
    create :desk_task_list, organization: organization
    create :desk_customer_satisfaction_survey_response, ticket: ticket, scale_choice: scale_choice
    create :customer_tag, organization: organization
    create :ticket_tag, organization: organization
    create :twitter_account, organization: organization
    create :outbound_message, organization: organization, rule: outbound_message_rule
    create :email_configuration, organization: organization
    create :round_robin_agent_slot, organization: organization
    create :tag, organization: organization

    create :ticket_field, :system_status, organization: organization
    create :desk_ticket_status, :closed, organization: organization

    assert_difference -> { Organization.count } => -1,
      -> { Desk::Twitter::Account.count } => -1,
      -> { Outbound::Message.count } => -1,
      -> { EmailConfiguration.count } => -1,
      -> { RoundRobinAgentSlot.count } => -1,
      -> { Tag.count } => -3,
      -> { Desk::CustomerSatisfaction::Survey.count } => -1,
      -> { Desk::Tag::CustomerTag.count } => -1,
      -> { Desk::Tag::TicketTag.count } => -1,
      -> { User.count } => -1,
      -> { SlackTeam.count } => -1,
      -> { OrganizationRole.count } => -1,
      -> { Desk::Task::List.count } => -1,
      -> { Outbound::Rule.count } => -1,
      -> { Setting.count } => -1,
      -> { Group.count } => -1,
      -> { Company.count } => -1,
      -> { Desk::Ticket::Status.count } => -1,
      -> { Desk::Ticket::Field.count } => -1,
      -> { Desk::Automation::Rule.count } => -1,
      -> { Desk::BusinessHour.count } => -1,
      -> { Desk::Macro::Rule.count } => -1,
      -> { Desk::Core::Rule.count } => -3 do
      organization.incinerate!
    end
  end

  def test_enabled_should_not_be_nil
    organization = build :organization, enabled: nil
    assert_not_nil organization.valid?
  end

  private

    def cached_data_with_subdomain(subdomain)
      Rails.cache.fetch("organizations/subdomains/#{subdomain}", expires_in: 12.hours) do
        Organization.active.includes(:setting).find_by(subdomain:)
      end
    end
end
