# frozen_string_literal: true

class Api::V1::Desk::TicketFieldsController < Api::V1::BaseController
  before_action :load_ticket_field!, only: [:show, :update, :destroy]
  before_action :ensure_access_to_manage_ticket_fields!, only: [:create, :update, :destroy]

  def index
    service = Desk::Ticket::Fields::SearchService.new(@organization, field_search_params)
    @ticket_fields = service.process
  end

  def create
    service = Desk::Ticket::Fields::CreatorService.new(field_params, @organization, **ticket_status_params.to_h)
    field = service.run

    if field.valid?
      render status: :ok, json: { notice: "Ticket Field has been successfully created." }
    else
      errors = field.errors.full_messages
      render status: :unprocessable_entity, json: { errors: }
    end
  end

  def show
    render
  end

  def update
    service = Desk::Ticket::Fields::UpdationService.new(@organization, @ticket_field, field_update_params)
    service.process

    if service.valid?
      if @ticket_field.saved_change_to_state?
        render json: {
          notice: "Ticket Field has been successfully #{field_params[:state] == "active" ? "activated" : "deactivated"}."
        }, status: :ok
      else
        render status: :ok, json: { notice: "Ticket Field has been successfully updated." }
      end
    else
      render status: :unprocessable_entity, json: { errors: service.errors }
    end
  end

  def destroy
    if @ticket_field.discard
      render status: :ok, json: { notice: "Ticket Field has been successfully deleted." }
    else
      render status: :unprocessable_entity, json: { errors: @ticket_field.errors.full_messages }
    end
  end

  private

    def field_search_params
      params.permit(:state, :search_term)
    end

    def field_params
      params.require(:ticket_field).permit(
        :id,
        :state,
        :agent_label,
        :customer_label,
        :is_required,
        :is_required_for_agent_when_submitting_form,
        :is_shown_to_customer,
        :is_editable_by_customer,
        :is_required_for_customer_when_submitting_form,
        :kind,
        :display_order,
        :is_required_for_agent_when_closing_ticket,
        ticket_field_options_attributes: [:id, :name, :display_order, :_destroy],
        ticket_field_regex_attributes: [:condition, :help_message],
      )
    end

    def ticket_status_params
      params.permit(ticket_statuses: [:name, :agent_label, :customer_label, :_destroy])
    end

    def field_update_params
      update_params = { ticket_field_params: field_params }

      if params[:ticket_statuses]
        update_params = update_params.merge(ticket_statuses: ticket_status_params[:ticket_statuses])
      end
      update_params
    end

    def load_ticket_field!
      @ticket_field = @organization.ticket_fields.find(params[:id])
    end
end
