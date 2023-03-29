# frozen_string_literal: true

class Desk::Ticketing::MergeService
  attr_accessor :primary_ticket, :organization, :user, :options, :errors, :response

  def initialize(primary_ticket, user, options)
    @primary_ticket = primary_ticket
    @organization = user.organization
    @user = user
    @options = options
    @errors = []
  end

  def process
    Ticket.transaction do
      process_secondary_tickets
      add_comment_on_primary_ticket

      raise ActiveRecord::Rollback if errors.present?

      secondary_tickets.update_all(status: "closed")
    end
  end

  def response
    if errors.empty?
      {
        json: {
          notice: I18n.t("notice.common", resource: "Ticket", action: "merged", count: secondary_tickets.size)
        },
        status: :ok
      }
    else
      { json: { errors: }, status: :unprocessable_entity }
    end
  end

  private

    def process_secondary_tickets
      secondary_tickets.each do |secondary_ticket|
        move_comments_to_primary_ticket(secondary_ticket)
        add_merge_comment_on_secondary_ticket(secondary_ticket)
        add_details_on_primary_ticket(secondary_ticket)
      end
    end

    def move_comments_to_primary_ticket(secondary_ticket)
      secondary_ticket.comments
        .where.not(comment_type: "description")
        .update_all(
          ticket_id: primary_ticket.id,
          latest: false
        )
    end

    def add_merge_comment_on_secondary_ticket(secondary_ticket)
      comment = Desk::Ticket::Comment::CreateService.new(secondary_ticket, secondary_ticket_comment_options).process
      unless comment.valid?
        errors << comment.errors.full_messages.to_sentence
      end
    end

    def add_details_on_primary_ticket(secondary_ticket)
      description = secondary_ticket.comments
        .where(comment_type: :description)
        .first.info.body.to_trix_html

      comment_options = {
        author: user,
        comment_type: "note",
        info: <<~TEXT
          Merged from ticket <a href="#{secondary_ticket.url}">##{secondary_ticket.number}</a>.
          <br>
          <br>
          <strong>Subject:</strong> #{secondary_ticket.subject}
          <br>
          <br>
          <strong>Description:</strong>
          <br>
          #{description}
          TEXT
      }

      comment = Desk::Ticket::Comment::CreateService.new(primary_ticket, comment_options).process
      unless comment.valid?
        errors << comment.errors.full_messages.to_sentence
      end
    end

    def add_comment_on_primary_ticket
      comment_options = {
        author: user,
        comment_type: options[:is_primary_comment_public] ? "reply" : "note",
        info: options[:primary_comment]
      }
      comment = Desk::Ticket::Comment::CreateService.new(primary_ticket, comment_options).process
      unless comment.valid?
        errors << comment.errors.full_messages.to_sentence
      end
    end

    def secondary_tickets
      @_secondary_tickets ||= @organization.tickets
        .includes(requester: :role, latest_comment: { ticket: [:response_time, :email_configuration] })
        .where(id: options[:secondary_ticket_ids])
    end

    def secondary_ticket_comment_options
      @_secondary_ticket_comment_options ||= {
        author: user,
        comment_type: options[:is_secondary_comment_public] ? "reply" : "note",
        info: options[:secondary_comment]
      }
    end
end
