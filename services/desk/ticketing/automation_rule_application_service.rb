# frozen_string_literal: true

module Desk::Ticketing
  class AutomationRuleApplicationService
    attr_accessor :ticket, :original_event, :performer,
      :applied_rule_ids, :skipped_rule_ids,
      :dependent_events, :executed_events

    def initialize(ticket, event, performer = nil)
      @ticket = ticket
      @performer = performer
      @original_event = event
      @applied_rule_ids = []
      @skipped_rule_ids = []
      @dependent_events = []
      @executed_events = []
    end

    # ==
    # process:
    #   1. Apply matching rules for original event
    #   2. If step 1 updated ticket, apply all matching rules
    #     for dependent triggers with appropriate events
    #     Eg. "status_changed" - when status is updated etc.
    #
    def process
      run_matching_rules(original_event, performer)
      run_on_update_matching_rules_for_dependent_events
      broadcast_updation if applied_rule_ids.present?
    end

    private

      # ==
      # Why until =>
      #   1.  Run all matching rules to a ticket
      #   2.  Then again check if any new rules are matching
      #       because of previous rule executions
      #   3.  Execute all newly marching rules
      def run_matching_rules(event_name, performed_by)
        rules = matching_rules(event_name, performed_by)

        until rules.empty?
          execute_rules!(rules)

          rules = matching_rules(event_name, performed_by)
        end
        @executed_events << event_name
      end

      def run_on_update_matching_rules_for_dependent_events
        events = get_pending_events

        until events.empty?
          events.each do |event_name|
            @skipped_rule_ids = []
            run_matching_rules(event_name, "system")
          end

          events = get_pending_events
        end
      end

      def get_pending_events
        @dependent_events.uniq - @executed_events
      end

      def execute_rules!(rules)
        ActiveRecord::Base.transaction do
          rules.each do |rule|
            is_rule_applied = false

            rule.actions.each do |action|
              result = action.execute!(ticket)

              if result
                @dependent_events += action.event_names
                is_rule_applied = true if !is_rule_applied
              end
            end

            if is_rule_applied
              record_log_entry!(rule)
              @applied_rule_ids << rule.id
            else
              @skipped_rule_ids << rule.id
            end
          end
        end
      end

      def matching_rules(event_name, performed_by)
        Desk::Automation::Rule.that_match(ticket.reload, event_name, performed_by, applied_rule_ids + skipped_rule_ids)
      end

      def record_log_entry!(rule)
        Desk::Automation::ExecutionLogEntry.create!(rule:, ticket_id: ticket.id)
      end

      def broadcast_updation
        TicketChannel.broadcast_ticket_updation(ticket)
      end
  end
end
