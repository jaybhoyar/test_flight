# frozen_string_literal: true

class Desk::Organizations::Seeder::Tickets
  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  def process!
    @cleo = create_cleo!
    create_tickets!
  end

  def create_tickets!
    options = YAML.load_file("config/seed/tickets.yml")

    options.each do |ticket_options|
      # 1. Create ticket
      ticket = organization.tickets.new ticket_options.except("comment")
      ticket.requester = @cleo
      ticket.save!

      # 2. Create ticket description
      body = ticket_options["comment"] % { organization_name: organization.name }

      ticket.comments.create! \
        info: body,
        author: @cleo,
        message_id: random_message_id,
        in_reply_to_id: random_message_id,
        comment_type: :description
    end
  end

  def create_cleo!
    organization.users.create \
      role: agent_role,
      first_name: "Cleo",
      email: "cleo@neeto.com",
      password: dummy_password,
      password_confirmation: dummy_password,
      internal: true
  end

  def agent_role
    organization.roles.where(name: Organization::AGENT_ROLE_NAME).first
  end

  private

    def dummy_password
      @_dummy_password ||= Time.now.to_i.to_s
    end

    def random_message_id
      SecureRandom.hex(10)
    end
end
