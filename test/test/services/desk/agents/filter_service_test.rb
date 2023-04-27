# frozen_string_literal: true

require "test_helper"

class Desk::Agents::FilterServiceTest < ActiveSupport::TestCase
  def setup
    @user = create(:user_with_agent_role)
    @organization = @user.organization
  end

  def test_agent_filter_without_filter_params
    empty_filter_params = {}

    agents = Desk::Agents::FilterService.new(all_organization_agents, empty_filter_params).process
    assert_equal 1, agents.count
  end

  def test_agent_filter_with_filter_params
    filter_params = { filters: { search_string: @user.first_name } }

    agents = Desk::Agents::FilterService.new(all_organization_agents, filter_params).process
    assert_equal 1, agents.count
  end

  def test_agent_filter_with_not_matching_filter_params
    filter_params = { filters: { search_string: "invalid_user_name" } }

    agents = Desk::Agents::FilterService.new(all_organization_agents, filter_params).process
    assert_empty agents
  end

  private

    def all_organization_agents
      @organization.agents
    end
end
