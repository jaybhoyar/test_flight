# frozen_string_literal: true

require "test_helper"

class Desk::Macro::DeletionServiceTest < ActiveSupport::TestCase
  def setup
    @user = create :user
    @organization = @user.organization
  end

  def test_desk_macros_deletion
    create_multiple_desk_macros
    service = Desk::Macro::DeletionService.new([@macro_1, @macro_2])

    assert_difference "@organization.desk_macros.count", -2 do
      service.process
    end

    assert service.success?
    assert_equal "Canned responses have been successfully deleted.", service.response
    end

  def test_desk_macro_deletion
    create_multiple_desk_macros
    service = Desk::Macro::DeletionService.new([@macro_1])

    assert_difference "@organization.desk_macros.count", -1 do
      service.process
    end

    assert service.success?
    assert_equal "Canned response has been successfully deleted.", service.response
  end

  private

    def create_multiple_desk_macros
      @macro_1 = create :desk_macro_rule, organization: @organization,
        name: "Set Priority to High",
        actions_attributes: [
                          { name: "change_priority", value: "high" }
                        ],
        record_visibility_attributes: {
          visibility: :all_agents
        }
      @macro_2 = create :desk_macro_rule, organization: @organization,
        name: "Mark Solved",
        actions_attributes: [
                          { name: "change_status", value: "Solved" }
                        ],
        record_visibility_attributes: {
          creator_id: @user.id,
          visibility: :all_agents
        }
    end
end
