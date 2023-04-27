# frozen_string_literal: true

class Api::V1::Desk::Macros::ExecutionsController < Api::V1::BaseController
  before_action :load_macro!, only: :create
  before_action :load_ticket!, only: :create

  def create
    execute_actions

    if @ticket.valid?
      load_ticket_with_associations
      render "api/v1/desk/tickets/show"
    else
      render json: {
        errors: @ticket.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

    def load_macro!
      @macro = @organization.desk_macros.find(params[:macro_id])
    end

    def load_ticket!
      @ticket = @organization.tickets.find(params[:ticket_id])
    end

    def load_ticket_with_associations
      @ticket = Ticket
        .includes(organization: [ordered_ticket_fields: [:ticket_field_options, :ticket_field_regex]])
        .find(@ticket.id)
    end

    def execute_actions
      ::Ticket.transaction do
        @macro.actions.each do |action|
          next if action.name == "add_reply" || action.name == "add_note"

          result = action.execute!(@ticket)
          raise ActiveRecord::Rollback unless result
        end
      end
    end
end
