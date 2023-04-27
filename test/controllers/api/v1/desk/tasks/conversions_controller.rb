# frozen_string_literal: true

class Api::V1::Desk::Tasks::ConversionsController < Api::V1::BaseController
  def create
    task = Task.find(params[:task_id])

    service = Desk::Tasks::ConvertToTicketService.new(task, current_user)
    service.process

    render json: service.response, status: service.status
  end
end
