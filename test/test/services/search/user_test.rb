# frozen_string_literal: true

require "test_helper"
class Search::UserTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @agent_role = create :organization_role_agent, organization: @organization
    @org_user1 = create :user, organization: @organization,
      name: "Paul Walker",
      email: "paul@gmail.com",
      role: @agent_role

    @org_user2 = create :user, organization: @organization,
      name: "Hugh Jackman",
      email: "jugh@yahoo.com",
      role: @agent_role

    @org_user3 = create :user, organization: @organization,
      name: "Adrien Borrdy",
      email: "adrien@outlook.com",
      role: @agent_role

    @org_user4 = create :user, organization: @organization,
      name: "Luka Modric",
      email: "luka@orkut.com",
      role: @agent_role

    @org_user5 = create :user, organization: @organization,
      first_name: "Luka Modric",
      last_name: "Lowel Gobbs",
      email: "lukaslowel@orkut.com",
      role: @agent_role

    @org_user6 = create :user, organization: @organization,
      first_name: "Kaylee",
      last_name: "Gutwoski",
      email: "kaylee@orkut.com",
      role: @agent_role

    @org_user7 = create :user, organization: @organization,
      first_name: "Oliver",
      last_name: "Gutwoski",
      email: "oliver@orkut.com",
      role: @agent_role

    @org_user8 = create :user, organization: @organization,
      first_name: "Kaylee",
      last_name: "Smith",
      email: "smith@orkut.com",
      role: @agent_role
  end

  def test_that_org_users_are_matched_by_first_name
    service = Search::User.new(@organization, "paul")

    assert_includes service.search, @org_user1
  end

  def test_that_org_users_are_matched_partially_by_last_name
    service = Search::User.new(@organization, "jack")

    assert_includes service.search, @org_user2
  end

  def test_that_org_users_are_matched_partially_by_email
    service = Search::User.new(@organization, "outlook")

    assert_includes service.search, @org_user3
  end

  def test_that_org_users_are_matched_by_full_name
    service = Search::User.new(@organization, "Luka Modric")

    assert_includes service.search, @org_user4
  end

  def test_that_admin_org_users_are_matched
    service = Search::User.new(@organization, "luka")

    assert_includes service.search, @org_user4
  end

  def test_that_org_users_are_matched_by_multiple_words
    service = Search::User.new(@organization, "luka modric lowel gobbs")

    assert_includes service.search, @org_user5
  end

  def test_that_specific_org_user_search_are_matched_by_that_specific_named_org_user_only
    service = Search::User.new(@organization, "Kaylee Gutwoski")

    assert_includes service.search, @org_user6
    assert_equal service.search.count, 1
  end
end
