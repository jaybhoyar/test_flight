# frozen_string_literal: true

class Desk::Automation::ActionExecutionService
  attr_reader :action, :ticket

  def initialize(action, ticket)
    @action = action
    @ticket = ticket
  end

  def run
    return if skippable?

    ticket.record_change_owner = action.rule
    send(action.name)
  end

  private

    ##
    # Main action methods
    #
    def set_tags
      ticket.tags = action.tags
    end

    def add_tags
      new_tags = action.tags - ticket.tags
      ticket.tags << new_tags.sort
    end

    def remove_tags
      new_tags = ticket.tags - action.tags
      ticket.tags = new_tags
    end

    def change_ticket_status
      ticket.update_attribute(:status, action.status)
    end

    def change_ticket_priority
      ticket.update(priority: action.value)
    end

    def assign_group
      ticket.update(group_id: action.actionable_id)
    end

    def assign_agent
      ticket.assign_agent(action.actionable_id)
    end

    def add_task_list
      task_list = ::Desk::Task::List.find(action.actionable_id)
      Desk::Ticketing::Tasks::ListCloneService.new(ticket, task_list).process
    end

    def email_to_requester
      ::AutomationMailer
        .with(organization_name: "", ticket_id: ticket.id, receiver_id: ticket.requester_id)
        .mail_to(tweaked_body)
        .deliver_later
    end

    def email_to_assigned_agent
      if ticket.agent
        Desk::Users::SendPushNotificationsService.new(ticket.agent)
          .notify(I18n.t("push_notification.assign.alert"), { message: I18n.t("push_notification.assign.message") })

        ::AutomationMailer
          .with(organization_name: "", ticket_id: ticket.id, receiver_id: ticket.agent_id)
          .mail_to(tweaked_body)
          .deliver_later
      end
    end

    def email_to_all_agents
      ticket
        .organization
        .users
        .available
        .joins(role: :permissions)
        .where(role: {
          permissions: {
            name: ["desk.view_tickets", "desk.reply_add_note_to_tickets", "desk.manage_tickets"]
          }
        })
        .distinct
        .find_each do |agent|

        Desk::Users::SendPushNotificationsService.new(agent)
          .notify(I18n.t("push_notification.new_ticket.alert"), {
            message: I18n.t("push_notification.new_ticket.message")
          })

        ::AutomationMailer
          .with(organization_name: "", ticket_id: ticket.id, receiver_id: agent.id)
          .mail_to(tweaked_body)
          .deliver_later
      end
    end

    def email_to_agent
      ::AutomationMailer
        .with(organization_name: "", ticket_id: ticket.id, receiver_id: action.actionable_id)
        .mail_to(tweaked_body)
        .deliver_later
    end

    def add_note
      ::Desk::Ticket::Comment::CreateService.new(ticket, note_params, true).process
    end

    def email_to
      action.value.split(",").each do |email_id|
        ::AutomationMailer
          .with(organization_name: "", ticket_id: ticket.id)
          .mail_to(tweaked_body, email_id)
          .deliver_later
      end
      true
    end

    def assign_to_first_responder
      comment = ticket.comments.without_description
        .where(author_type: "User", author_id: agent_ids)
        .in_order
        .first

      ticket.assign_agent(comment.author_id) if comment
    end

    def assign_to_last_responder
      comment = ticket.comments.without_description
        .where(author_type: "User", author_id: agent_ids)
        .in_order
        .last

      ticket.assign_agent(comment.author_id) if comment
    end

    def assign_agent_round_robin
      Desk::Automation::Actions::AssignAgentService.new(action, ticket).run_round_robin
    end

    def assign_agent_load_balanced
      Desk::Automation::Actions::AssignAgentService.new(action, ticket).run_load_balanced
    end

    def remove_assigned_agent
      ticket.update(agent_id: nil)
    end

    def message_to_slack
      team = ticket.organization.slack_team

      if team.present?
        message = substitute_email_variables(action.body.to_plain_text)
        response = team.post_message(message, action.value)
        if response.is_a?(Hash) && response[:error]
          disable_rule_with_activity("activity.core_rule.disable.no_slack_channel")
          false
        end
      else
        disable_rule_with_activity("activity.core_rule.disable.slack_not_configured")
        false
      end
    end

    ##
    # Helper methods
    #
    def tweaked_body
      @_tweaked_body ||= substitute_email_variables(action.body.body&.to_html)
    end

    def note_params
      {
        info: tweaked_body,
        comment_type: "note",
        author_type: "Desk::Core::Rule",
        author_id: action.rule.id,
        attachments: action_attachments
      }
    end

    def action_attachments
      action.attachments.map do |attachment|
        {
          io: StringIO.new(attachment.download),
          filename: attachment.filename,
          content_type: attachment.content_type
        }
      end
    end

    def substitute_email_variables(template_str)
      placeholders_vars = ::Placeholders::VariablesCarrier.new(ticket)

      template = Liquid::Template.parse(template_str)
      template.render(placeholders_vars.build)
    end

    def agent_ids
      ticket.organization.not_customer_ids
    end

    def disable_rule_with_activity(key)
      action.rule.skip_activity_log = true
      action.rule.update(active: false)
      action.rule.log_activity!(key, {})
    end

    def skippable?
      ::Desk::Automation::Actions::SkippableActionService.new(action, ticket).skippable?
    end
end
