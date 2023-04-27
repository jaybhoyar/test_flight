# frozen_string_literal: true

require "test_helper"

class Desk::Tasks::ConvertToTicketServiceTest < ActiveSupport::TestCase
  def setup
    @agent_adam = create(:user_with_agent_role)
    @organization = @agent_adam.organization
    customer_eve = create(:user, organization: @organization, role: nil)
    @ticket = create(
      :ticket, :with_desc, organization: @organization, requester: customer_eve, agent: @agent_adam,
      number: 2, category: "Questions")
    @task = @ticket.tasks.create(name: "Site installation", info: "Site installation service.")
  end

  def test_that_task_is_converted_to_ticket
    conversion_service = Desk::Tasks::ConvertToTicketService.new(@task, @agent_adam)

    assert_difference "Ticket.count", 1 do
      conversion_service.process
    end

    converted_ticket = conversion_service.converted_ticket

    ticket_comment = @ticket.comments.where(comment_type: "description").first
    converted_ticket_comment = converted_ticket.comments.where(comment_type: "description").first

    assert_equal :ok, conversion_service.status
    assert_equal @task.name, converted_ticket.subject
    assert_equal @ticket.requester, converted_ticket.requester
    assert_equal @agent_adam, converted_ticket.submitter
    assert_equal @task, converted_ticket.parent_task
    assert_includes converted_ticket_comment.info.to_s, %{Subticket of <a href="#{@ticket.url}">##{@ticket.number}</a>}
    assert_equal ticket_comment.message_id, converted_ticket_comment.message_id
    assert_equal ticket_comment.in_reply_to_id, converted_ticket_comment.in_reply_to_id
    assert conversion_service.response[:task][:has_converted_ticket]
  end
end
