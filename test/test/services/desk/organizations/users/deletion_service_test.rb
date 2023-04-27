# frozen_string_literal: true

require "test_helper"

class Desk::Organizations::Users::DeletionServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @user = create(:user, organization: @organization)
    @agent_role = create(:organization_role_agent, organization: @organization)

    create_multiple_agents
  end

  def test_process_success
    user_deletion_service = Desk::Organizations::Users::DeletionService.new(agents).process

    assert_equal "Agents have been successfully removed.", user_deletion_service
  end

  private

    def create_multiple_agents
      5.times do
        create(:ticket, agent_id: @user.id)
      end
    end

    def agents
      @organization.users.where(role: @agent_role)
    end
end
