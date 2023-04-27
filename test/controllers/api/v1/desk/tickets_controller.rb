# frozen_string_literal: true

class Api::V1::Desk::TicketsController < Api::V1::BaseController
  include Pagination

  DEFAULT_SORT_ORDER = { "column": "number", "direction": "DESC" }

  before_action :load_ticket!, only: [:update, :destroy]
  before_action :load_tickets!, only: :update_multiple
  before_action :load_ticket_with_associations, only: [:show]
  before_action :ensure_access_to_view_tickets!, only: [:index, :show]
  before_action :ensure_access_to_create_tickets!, only: :create
  before_action :ensure_access_to_manage_tickets!, only: [:update, :update_multiple, :destroy]

  def index
    all_filtered_sorted_tickets
  end

  def show
    @user = @ticket.requester
  end

  def create
    @ticket = ticket_creator_service.run

    if @ticket.errors.empty?
      render status: :ok, json: { notice: "Ticket has been successfully created." }
    else
      render status: :unprocessable_entity, json: { errors: @ticket.errors.full_messages }
    end
  end

  def update
    process_ticket_update

    if @ticket.valid?
      render "show"
    else
      render status: :unprocessable_entity, json: { errors: @ticket.errors.full_messages }
    end
  end

  def update_multiple
    service = Desk::Ticketing::UpdateMultipleService.new(@tickets, params[:ticket])
    service.process

    if service.success?
      render json: { notice: service.response }, status: :ok
    else
      render json: { errors: service.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if @ticket.destroy
      render json: { notice: "Ticket #{@ticket.number} has been successfully deleted." }, status: :ok
    else
      render json: { errors: @ticket.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def load_ticket!
      @ticket = @organization.tickets.includes(include_associations).find_by!(id: params[:id])

      authorize @ticket
    end

    def load_tickets!
      @tickets = @organization.tickets
        .includes(include_associations, :parent_task)
        .where!(id: params[:ticket][:ids])

      @tickets.each do |ticket|
        authorize ticket, :update?
      end
    end

    def ticket_params
      params.require(:ticket).permit(
        :subject, :agent_id, :group_id, :status, :priority, :category, :status,
        :customer_email, :resolution_due_date, :number, :tags, :spam, :trash,
        deleted_attachments: [],
        comments_attributes: [:id, :info, attachments: []],
        ticket_field_responses_attributes: [:ticket_field_id, :ticket_field_option_id, :value, :id, :_destroy],
        tags: [:id, :name]
      )
    end

    def all_filtered_sorted_tickets
      @sort_order_of_view = applied_sort_order

      filtered_tickets = Desk::Ticketing::Filter::FilterService
        .new(@organization, ticket_filter_or_sort_params, default_or_custom_filter_tickets)
        .process

      filtered_tickets_with_associations = filtered_tickets
        .includes(:agent, :group)
        .page(current_page)
        .per(per_page_limit)

      @tickets = Desk::Ticketing::SortService.new(
        filtered_tickets_with_associations,
        filter_or_sort_options).sorted_tickets
    end

    def filter_or_sort_options
      filter_or_sort_params = ticket_filter_or_sort_params
      if (custom_view? && @sort_order_of_view["column"].nil?) || (!custom_view? && sort_column_empty?)
        filter_or_sort_params[:sort_by] = DEFAULT_SORT_ORDER
      elsif custom_view? && sort_column_empty?
        filter_or_sort_params[:sort_by] = @sort_order_of_view
      end

      filter_or_sort_params
    end

    def custom_view?
      @_is_custom_view ||= ticket_filter_or_sort_params[:is_custom_view] == "true"
    end

    def sort_column_empty?
      sort_by_param = ticket_filter_or_sort_params[:sort_by]
      sort_by_column = sort_by_param.present? ? sort_by_param[:column] : nil
      return true if sort_by_column.nil? || sort_by_column.empty?
    end

    def default_or_custom_filter_tickets
      options = ticket_filter_or_sort_params
      tickets = if custom_view?
        custom_filter_tickets(options[:base_filter_by])
      else
        Desk::Ticketing::Filter::DefaultFilterService
          .new(@organization, options[:base_filter_by], current_user, options[:customer_id])
          .process
      end

      if current_user.can_only_manage_own_tickets?
        tickets = tickets.where(agent_id: current_user.id)
      end
      tickets
    end

    def custom_filter_tickets(base_filter_by)
      view = @organization.views.find_by!(title: base_filter_by)
      @sort_order_of_view = {
        "column" => view.sort_column || DEFAULT_SORT_ORDER[:column],
        "direction" => view.sort_direction || DEFAULT_SORT_ORDER[:direction]
      }
      @custom_filtered_tickets = view.rule.matching_tickets.includes(:requester)
    end

    def applied_sort_order
      col = ticket_filter_or_sort_params.dig(:sort_by, :column).presence || DEFAULT_SORT_ORDER[:column]
      dir = ticket_filter_or_sort_params.dig(:sort_by, :direction).presence || DEFAULT_SORT_ORDER[:direction]

      { "column": col, "direction": dir }
    end

    def ticket_creator_service
      Desk::Ticketing::TicketCreatorService.new(
        current_user,
        ticket_params[:subject],
        ticket_params[:comments_attributes][:info],
        @organization,
        nil,
        nil,
        nil,
        extra_ticket_creator_service_params
      )
    end

    def process_ticket_update
      ticket_update_service = Desk::Ticketing::UpdateTicketService.new(
        @organization,
        @ticket,
        current_user,
        ticket_params
      )
      ticket_update_service.process
    end

    def extra_ticket_creator_service_params
      {
        channel: ::Ticket.channels[:ui],
        status: ticket_params[:status],
        priority: ticket_params[:priority],
        category: ticket_params[:category],
        customer_email: ticket_params[:customer_email],
        ticket_field_responses_attributes: ticket_params[:ticket_field_responses_attributes],
        attachments: ticket_params[:comments_attributes][:attachments],
        agent_id: ticket_params[:agent_id],
        group_id: ticket_params[:group_id]
      }
    end

    def load_ticket_with_associations
      @ticket = if params[:number].present?
        @organization.tickets.includes(include_associations).find_by!(number: params[:number])
      else
        @organization.tickets.includes(include_associations).find_by!(id: params[:id])
      end

      authorize @ticket
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "Could not find the ticket." }, status: :not_found
    end

    def include_associations
      [
        :tags, :ticket_field_responses, :requester,
        agent: :customer_detail,
        activities: :owner,
        tasks: :converted_ticket,
        organization: { ordered_ticket_fields: [:ticket_field_options, :ticket_field_regex] },
        ordered_comments: [
          :attachments_attachments,
          :rich_text_info,
          author: [:customer_detail, :role],
        ]
      ]
    end

    def ticket_filter_or_sort_params
      params.require(:ticket).permit(
        :first,
        :base_filter_by,
        :is_custom_view,
        :customer_id,
        include_models: [:value],
        filter_by: [:node, :rule, :value],
        sort_by: [:column, :direction]
      )
    end
end
