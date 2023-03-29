# frozen_string_literal: true

class Desk::Organizations::Roles::UpdateService
  attr_reader :organization_role, :options, :response

  def initialize(organization_role, options)
    @organization_role = organization_role
    @options = options
  end

  def process
    @response = if options[:verified].blank? && affects_tickets?
      response_warning
    elsif @organization_role.update(role_options)
      remove_assigned_tickets if affects_tickets?

      response_success
    else
      response_errors(@organization_role.errors.full_messages)
    end
  end

  private

    def remove_assigned_tickets
      tickets = Ticket.where(agent_id: @organization_role.agent_ids)
      ticket_ids = tickets.pluck(:id)
      tickets.update_all(agent_id: nil)

      Desk::Ticket::Follower
        .where(user_id: @organization_role.agent_ids, ticket_id: ticket_ids)
        .destroy_all
    end

    def remove_assigned_chats
      Chat::Conversation.where(user_id: @organization_role.agent_ids).update_all(user_id: nil)
    end

    def response_warning
      {
        json: {
          success: false,
          notice: "All the #{modifications_string} assigned to the users belonging to this role will be marked as unassigned."
        }, status: :ok
      }
    end

    def response_success
      { json: { success: true, notice: "Role has been successfully updated." }, status: :ok }
    end

    def response_errors(errors)
      { json: { errors: }, status: :unprocessable_entity }
    end

    def role_options
      options.require(:organization_role).permit(:id, :name, :kind, :description, permission_ids: [])
    end

    def modifications_string
      affects_tickets? ? "tickets" : ""
    end

    def affects_tickets?
      @_affects_tickets ||= has_assigned_tickets? && !includes_permission_to_manage_tickets?
    end

    def includes_permission_to_manage_tickets?
      includes_permissions? ["desk.manage_own_tickets", "desk.reply_add_note_to_tickets", "desk.manage_tickets"]
    end

    def includes_permissions?(permissions)
      Permission.where(id: role_options[:permission_ids], name: permissions).exists?
    end

    def has_assigned_tickets?
      Ticket.where(agent: @organization_role.agent_ids).exists?
    end
end
