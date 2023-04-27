# frozen_string_literal: true

require "test_helper"

class Desk::Organizations::Users::UpdateServiceTest < ActiveSupport::TestCase
  def setup
    @group = create(:group)
    @organization = @group.organization
    @user = create(:user, organization: @organization)
    @group_member = @group.group_members.create(user: @user)
    @current_user = create(:user, organization: @organization)
    create(:ticket, agent_id: @user.id)
    create(:ticket, agent_id: @user.id)
    create(:ticket, agent_id: @user.id)
  end

  def test_process_success_without_unassigning_tickets
    service = Desk::Organizations::Users::UpdateService.new(
      @user, @current_user,
      user_attributes.except(:unassign_tickets))
    service.process

    assert_equal :ok, service.response[:status]
    assert_equal "Details has been successfully updated.", service.response[:json][:notice]
    assert_not @user.reload.available_for_desk
    assert_not @user.reload.continue_assigning_tickets
  end

  def test_process_success_with_unassigning_tickets
    service = Desk::Organizations::Users::UpdateService.new(
      @user, @current_user,
      user_attributes)

    assert_difference "Ticket.where(agent_id: @user.id).count", -3 do
      service.process
    end

    assert_equal :ok, service.response[:status]
    assert_equal "All tickets have been successfully unassigned.", service.response[:json][:notice]
  end

  def test_that_password_is_updated
    stub_request(:put, ->(uri) { uri.to_s.include?("/api/v1/clients/users") }).with(
      body: hash_including(
        {
          "user" => hash_including({ email: @user.email })
        }),
      headers: {
        "Authorization" => "Bearer",
        "Content-Type" => "application/x-www-form-urlencoded"
      }
    ).to_return(status: 200, body: "", headers: {})

    Desk::Organizations::Users::UpdateService.any_instance.stubs(:sso_enabled?).returns(true)

    password_params = { password: "passMe123", password_confirmation: "passMe123" }
    service = Desk::Organizations::Users::UpdateService.new(
      @user, @current_user,
      password_params)
    service.process
    @user.reload

    assert @user.valid_password?("passMe123")
  end

  private

    def user_attributes
      {
        available_for_desk: false,
        continue_assigning_tickets: false,
        unassign_tickets: true
      }
    end
end
