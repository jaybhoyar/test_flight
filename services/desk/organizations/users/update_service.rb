# frozen_string_literal: true

class Desk::Organizations::Users::UpdateService
  include SSOHelpers

  attr_reader :user, :options, :current_user, :options, :notice, :errors, :success

  def initialize(user, current_user, options)
    @user = user
    @current_user = current_user
    @options = options
    @errors = []
    @success = true
  end

  def process
    return role_change_warning if changes_role? && affects_tickets?

    ::User.transaction do
      user.update!(user_attributes)

      @notice = profile_update_response
      unassign_all_tickets if options[:unassign_tickets]

      if user.saved_change_to_organization_role_id?
        remove_assigned_tickets_with_followers if affects_tickets?
      end
    end
    Users::UserUpdaterService.new(current_user, user).process if sso_enabled?
  rescue ActiveRecord::RecordInvalid => invalid
    @errors += invalid.record.errors.full_messages
  rescue ActiveRecord::StatementInvalid => exception
    @errors << exception.message
  rescue ActiveRecord::ActiveRecordError => exception
    @errors << exception.message
  end

  def response
    if errors.empty?
      { json: { notice:, success: }, status: :ok }
    else
      { json: { errors: }, status: :unprocessable_entity }
    end
  end

  private

    def user_attributes
      options.except(:unassign_tickets, :time_zone_offset, :change_role)
    end

    def unassign_all_tickets
      Ticket.where(agent_id: user.id).update(agent_id: nil)
      @notice = "All tickets have been successfully unassigned."
    end

    def profile_update_response
      "Details has been successfully updated."
    end

    def role_change_warning
      @notice = "All the assigned tickets will be marked as unassigned as the new role does not have these permissions."
      @success = false
    end

    def changes_role?
      options[:organization_role_id].present? &&
        options[:organization_role_id] != user.organization_role_id &&
        options[:change_role].blank?
    end

    def affects_tickets?
      @_affects_tickets ||= has_assigned_tickets? && !new_role_can_manage_tickets?
    end

    def new_role_can_manage_tickets?
      new_role.permissions.exists? \
        name: ["desk.manage_own_tickets", "desk.reply_add_note_to_tickets", "desk.manage_tickets"]
    end

    def new_role
      @_new_role ||= OrganizationRole.find(options[:organization_role_id])
    end

    def has_assigned_tickets?
      Ticket.where(agent_id: user.id).exists?
    end

    def remove_assigned_tickets_with_followers
      tickets = Ticket.where(agent_id: @user.id)
      ticket_ids = tickets.pluck(:id)
      tickets.update_all(agent_id: nil)

      Desk::Ticket::Follower
        .where(user_id: @user.id, ticket_id: ticket_ids)
        .destroy_all
    end
end
