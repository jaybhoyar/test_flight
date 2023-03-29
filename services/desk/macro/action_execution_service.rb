# frozen_string_literal: true

class Desk::Macro::ActionExecutionService
  attr_reader :action, :ticket

  def initialize(action, ticket)
    @action = action
    @ticket = ticket
  end

  def run
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

    def change_status
      ticket.update(status: action.value)
    end

    def change_priority
      ticket.update(priority: action.value)
    end

    def assign_group
      ticket.update(group_id: action.actionable_id)
    end

    def assign_agent
      ticket.assign_agent(action.actionable_id)
    end
end
