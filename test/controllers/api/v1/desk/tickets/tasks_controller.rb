# frozen_string_literal: true

class Api::V1::Desk::Tickets::TasksController < Api::V1::BaseController
  before_action :load_ticket!
  before_action :load_task!, only: [:destroy, :update]
  before_action :ensure_access_to_view_tickets!, only: :index
  before_action :ensure_access_to_manage_tickets!,
    only: [:create, :update, :destroy, :create_multiple, :update_multiple]

  def index
    @tasks = @ticket.tasks.includes(:converted_ticket)
  end

  def create
    @task = @ticket.tasks.new(task_params)

    if @task.save
      render status: :created
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @task.update(task_params)
      render
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @task.destroy
      render json: { success: true, notice: I18n.t("resource.delete", resource_name: "Task") }
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create_multiple
    service = Desk::Ticketing::Tasks::CreateMultipleService.new(@ticket, tasks_params)
    service.process

    render json: { tasks: service.tasks, notice: service.response }, status: :ok
  end

  def update_multiple
    if @ticket.update(ticket_tasks_params)
      @tasks = @ticket.tasks.includes(:converted_ticket)
      render :index
    else
      render json: { errors: @ticket.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private

    def load_ticket!
      @ticket = @organization.tickets.includes(tasks: :converted_ticket).find_by!(id: params[:ticket_id])
    end

    def load_task!
      @task = @ticket.tasks.find(params[:id])
    end

    def task_params
      params.require(:task).permit(:name, :status)
    end

    def tasks_params
      params.permit(tasks: [:name])
    end

    def ticket_tasks_params
      params.require(:ticket).permit(
        tasks_attributes: [:id, :sequence, :_destroy]
      )
    end
end
