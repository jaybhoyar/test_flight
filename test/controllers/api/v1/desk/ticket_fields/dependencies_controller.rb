# frozen_string_literal: true

class Api::V1::Desk::TicketFields::DependenciesController < Api::V1::BaseController
  before_action :load_ticket_field!

  def index
    render json: {
      dependencies: load_condition_dependencies,
      affected_tickets_count: load_affected_tickets_count
    }, status: :ok
  end

  private

    def load_ticket_field!
      @ticket_field = @organization.ticket_fields.find(params[:ticket_field_id])
    end

    def load_condition_dependencies
      matches = ::Desk::Core::Condition
        .includes(conditionable: :rule)
        .where(field: @ticket_field.id)
        .group_by(&:conditionable_id)

      matches.map do |key, values|
        conditionable = values.first.conditionable

        if conditionable.is_a? View::Rule
          {
            id: conditionable.view.id,
            name: conditionable.view.title,
            type: "View"
          }
        else
          {
            id: conditionable.rule.id,
            name: conditionable.rule.name,
            type: conditionable.rule.type
          }
        end
      end
    end

    def load_affected_tickets_count
      @ticket_field.ticket_field_responses.count
    end
end
