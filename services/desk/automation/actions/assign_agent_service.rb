# frozen_string_literal: true

class Desk::Automation::Actions::AssignAgentService
  attr_reader :action, :ticket, :organization

  def initialize(action, ticket)
    @action = action
    @ticket = ticket
    @organization = ticket.organization
  end

  def run_round_robin
    next_agent_id = next_round_robin_agent_id

    if next_agent_id.present?
      update_round_robin_slot(next_agent_id)
      ticket.assign_agent(next_agent_id)
    end
  end

  def run_load_balanced
    agent_id = agent_id_with_least_tickets
    ticket.assign_agent(agent_id) if agent_id
  end

  def available_agent_ids
    @_available_agent_ids ||= begin
      if group_id.nil?
        ticket.organization.agents
          .where(continue_assigning_tickets: true)
          .order(:created_at)
          .pluck(:id)
      else
        ticket.group.users
          .where(continue_assigning_tickets: true)
          .order(:created_at)
          .pluck(:id)
      end
    end
  end

  private

    def next_round_robin_agent_id
      next_agent_index = if last_round_robin_agent_id.present?
        available_agent_ids.find_index(last_round_robin_agent_id) + 1
      else
        0
      end

      available_agent_ids[next_agent_index].presence || available_agent_ids.first
    end

    def supported_email_variables
      @_supported_email_variables ||= ::Automation::EmailFieldsCarrier::SUPPORTED_VARIABLES
    end

    def last_round_robin_agent_id
      @_last_round_robin_agent_id ||= begin
        slot = organization.round_robin_agent_slots.where(group_id:).first
        slot&.user_id
      end
    end

    def agent_id_with_least_tickets
      agents_list = ::Ticket.where(organization_id: ticket.organization_id)
        .where(agent_id: available_agent_ids)
        .where(status: ["new", "open"])
        .where.not(agent_id: nil)
        .group(:agent_id).count

      missing_agent_ids = available_agent_ids - agents_list.keys

      return missing_agent_ids.first if missing_agent_ids.present?
      return if agents_list.keys.empty?

      agents_list.min_by { |k, v| v }.first
    end

    def update_round_robin_slot(agent_id)
      slot = organization.round_robin_agent_slots.find_or_initialize_by(group_id:)
      slot.user_id = agent_id
      slot.save!
    end

    def group_id
      @_group_id ||= ticket.group_id
    end
end
