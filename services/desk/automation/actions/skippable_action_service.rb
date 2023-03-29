# frozen_string_literal: true

module Desk
  module Automation
    module Actions
      class SkippableActionService
        attr_reader :action, :ticket

        def initialize(action, ticket)
          @action = action
          @ticket = ticket
        end

        def skippable?
          return false unless skippable_action?

          send("skip_#{action.name}?")
        end

        private

          def skip_assign_group?
            ticket.group_id == action.actionable_id
          end

          def skip_change_ticket_priority?
            ticket.priority == action.value
          end

          def skip_change_ticket_status?
            ticket.status == action.status
          end

          def skip_assign_agent?
            ticket.agent_id == action.actionable_id
          end

          def skip_remove_assigned_agent?
            ticket.agent_id.nil?
          end

          def skippable_action?
            ::Desk::Automation::Action.names.slice(
              :assign_group, :change_ticket_priority, :change_ticket_status,
              :assign_agent, :remove_assigned_agent
            ).has_key?(action.name)
          end
      end
    end
  end
end
