# frozen_string_literal: true

class Desk::Tasks::ConvertToTicketService
  TASK_RESPONSE_ATTRIBUTES = %w(id ticket_id name status info sequence).freeze
  TICKET_RESPONSE_ATTRIBUTES = %w(id number status).freeze

  attr_reader :task, :current_user, :ticket, :converted_ticket, :response

  def initialize(task, current_user)
    @task = task
    @current_user = current_user
    @ticket = task.ticket
    @response = {}
  end

  def process
    begin
      @converted_ticket = Ticket.create!(ticket_attributes)
      Desk::Tasks::ActivityTrackerService.new(task, "sub_ticket").process
      set_success_response
    rescue ActiveRecord::RecordInvalid => invalid_record
      set_error_response(invalid_record.record)
    end
  end

  def status
    success? ? :ok : :unprocesseable_entity
  end

  def success?
    !response[:errors].present?
  end

  private

    def ticket_attributes
      {
        requester: ticket.requester,
        submitter: current_user,
        subject: task.name,
        organization: ticket.organization,
        agent_id: current_user.id,
        channel: ticket.channel,
        status: Ticket::INITIAL_STATUS,
        priority: ticket.priority,
        category: ticket.category,
        parent_task_id: @task.id,
        comments_attributes:
      }
    end

    def comments_attributes
      description_comment = ticket.comments.where(comment_type: "description").first

      [{
        author: current_user,
        in_reply_to_id: description_comment&.in_reply_to_id,
        message_id: description_comment&.message_id,
        latest: true,
        comment_type: "description",
        info: <<~TEXT
          Subticket of <a href="#{ticket.url}">##{ticket.number}</a>.
          TEXT
      }]
    end

    def set_error_response(record)
      @response[:errors] = record.errors.any? ? record.errors.full_messages : [I18n.t("generic_error")]
    end

    def set_success_response
      @response = {
        notice: I18n.t("task.converted_to_ticket"),
        task: task_response
      }.with_indifferent_access
    end

    def task_response
      task_response_object = task.attributes.slice(*TASK_RESPONSE_ATTRIBUTES)
      task_response_object.merge(
        {
          has_converted_ticket: true,
          converted_ticket: converted_ticket.attributes.slice(*TICKET_RESPONSE_ATTRIBUTES)
        })
    end
end
