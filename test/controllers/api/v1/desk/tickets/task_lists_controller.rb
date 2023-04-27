# frozen_string_literal: true

class Api::V1::Desk::Tickets::TaskListsController < Api::V1::BaseController
  before_action :load_ticket!
  before_action :load_task_list!

  def create
    service = Desk::Ticketing::Tasks::ListCloneService.new(@ticket, @task_list)
    service.process

    if service.success?
      render json: { tasks: service.tasks, notice: service.response }, status: :created
    else
      render json: { errors: service.errors }, status: :unprocessable_entity
    end
  end

  private

    def load_ticket!
      @ticket = @organization.tickets.find_by!(id: params[:ticket_id])
    end

    def load_task_list!
      @task_list = @organization.task_lists.find(params[:task_list][:id])
    end
end
