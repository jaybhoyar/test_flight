# frozen_string_literal: true

module SampleData
  class OrganizationTicketSeeder
    attr_reader :organization
    TAG_NAMES = [
      "Marketing", "VIP", "Urgent", "Campaign", "Event", "Networking",
      "Billing", "Credit-card", "Sms", "2FA", "Google-login"
    ]

    # Agents would have emails as [agentoliver, agentsyndi]@{organization.name.lowercase}.com
    # Each organization would have agents with emails as agentoliver@{organization.name.lowercase}.com

    def initialize(organization)
      @organization = organization
    end

    def seed_tickets
      add_ticket_fields

      ticket_created_at_lower_limit = Time.current - 5.months

      no_of_tickets_to_seed = 32
      tickets_per_month = no_of_tickets_to_seed / 12

      no_of_tickets_to_seed.times do |seed_ticket_number|
        customer = customers[seed_ticket_number % customers.length]
        agent = agents[seed_ticket_number % agents.length]
        User.current = agent

        # Create tickets_per_month tickets each month starting an year ago from now
        third_ticket = (seed_ticket_number + 1) % tickets_per_month == 0
        ticket_created_at_lower_limit = if third_ticket
          ticket_created_at_lower_limit + 1.week
        else
          ticket_created_at_lower_limit
        end

        upper_limit = ticket_created_at_lower_limit + 1.week

        ticket_created_at = random_time(ticket_created_at_lower_limit, upper_limit)
        ticket_subject = subjects[seed_ticket_number % subjects.size]

        if (seed_ticket_number / tickets_per_month) < 6
          ticket = organization.tickets.create!(
            subject: "#{seed_ticket_number}! #{ticket_subject}",
            requester: customer,
            organization:,
            status: "open",
            agent_id: agents[1].id,
            priority: Ticket.priorities.values.sample,
            created_at: ticket_created_at
                                             )
        else
          ticket = organization.tickets.create!(
            subject: ticket_subject,
            requester: customer,
            organization:,
            status: Ticket::DEFAULT_STATUSES.except(
              :spam, :trash,
              :resolved).values.sample,
            priority: Ticket.priorities.values.sample,
            created_at: ticket_created_at
                                              )
        end

        # Update first 4 tickets to spam and trash
        if (seed_ticket_number / tickets_per_month) < 2
          ticket.update!(status: Ticket::DEFAULT_STATUSES[:spam])
        elsif (seed_ticket_number / tickets_per_month) < 4
          ticket.update!(status: Ticket::DEFAULT_STATUSES[:trash])
        end

        ticket.activities.each do |activity|
          if activity.key == "activity.ticket.create"
            activity.update!(created_at: ticket.created_at, updated_at: ticket.created_at)
          end
        end

        # Add comments
        comment = add_first_comment!(ticket, customer, ticket_subject)
        2.times do |comment_number|
          comment = generate_agent_response(ticket, comment_number, comment, agent)
          comment = generate_customer_response(ticket, comment_number, comment, customer)
        end

        # Mark every fourth ticket resolved and send final response for the resolved tickets
        if (seed_ticket_number / tickets_per_month) % 4 == 0 && (seed_ticket_number / tickets_per_month) > 5
          comment = generate_comment!(
            ticket, agent, "Your ticket has been resolved", comment.message_id,
            comment.created_at)
          resolved_at = comment.created_at

          ticket.update!(status: Ticket::DEFAULT_STATUSES[:resolved])
          ticket.update!(
            resolved_at:,
            updated_at: resolved_at
          )

          ticket.activities.each do |activity|
            if activity.key == "activity.ticket.update.status"
              activity.update!(created_at: resolved_at, updated_at: resolved_at)
            end
          end
        end

        # Add tags
        random_tags = tags.sample([1, 2].sample)
        ticket.update(tags: random_tags)

        # Create survey responses
        if ticket.status == "resolved"
          generate_survey_responses_for_tickets_with_status_resolved(ticket)
        end
      end
    end

    def seed_huge_tickets
      add_ticket_fields

      priorities = Ticket.priorities.values

      10_000.times do |seed_ticket_number|
        customer = customers[seed_ticket_number % customers.length]
        agent = agents[seed_ticket_number % agents.length]
        User.current = agent

        created_at = Faker::Date.between(from: 1.year.ago, to: 5.days.ago)
        subject = Faker::Lorem.question
        description = Faker::Lorem.sentence

        # 1. Create ticket
        ticket = organization.tickets.new \
          subject: subject,
          requester: customer,
          priority: priorities.sample,
          status: "new",
          created_at: created_at

        assign_agent = [true, false].sample

        if assign_agent
          ticket.agent_id = agents[1].id
        end

        ticket.save!

        # 2. Create activities
        ticket.activities.find_by(key: "activity.ticket.create").update(
          created_at: ticket.created_at,
          updated_at: ticket.created_at
        )

        # 3. Add comments
        comment = create_a_comment!(ticket, customer, nil, comment_type: :description, created_at:)

        [*0..5].sample.times do |number_of_comments|
          comment = create_a_comment!(ticket, agent, comment)
          comment = create_a_comment!(ticket, customer, comment)
        end

        # 4. Change status
        updated_at = comment.created_at
        case [*0..9].sample
        when 0 # trash
          ticket.update!(
            status: Ticket::DEFAULT_STATUSES[:trash],
            updated_at:
          )
        when 1 # spam
          ticket.update!(
            status: Ticket::DEFAULT_STATUSES[:spam],
            updated_at:
          )
        when 2 # resolved
          comment = create_a_comment!(
            ticket, agent, comment,
            info: "Your ticket has been Resolved. Please feel free to reopen the ticket if needed.")

          ticket.update!(
            status: Ticket::DEFAULT_STATUSES[:resolved],
            resolved_at: updated_at,
            updated_at:
          )

          ticket.activities.find_by(key: "activity.ticket.update.status").update(
            created_at: updated_at,
            updated_at:
          )
        when 3 # closed
          comment = create_a_comment!(
            ticket, agent, comment,
            info: "Your ticket has been closed. Please feel free to reopen the ticket if needed.")

          ticket.update!(
            status: Ticket::DEFAULT_STATUSES[:closed],
            resolved_at: updated_at,
            updated_at:
          )

          ticket.activities.find_by(key: "activity.ticket.update.status").update(
            created_at: updated_at,
            updated_at:
          )
        when 4, 5, 6 # open
          ticket.update!(
            status: Ticket::DEFAULT_STATUSES[:open],
            updated_at:
          )
        else
          # Do nothing
        end

        # Add tags
        random_tags = tags.sample([1, 2].sample)
        ticket.update(tags: random_tags)

        # Create survey responses
        if ticket.status == "resolved"
          generate_survey_responses_for_tickets_with_status_resolved(ticket)
        end

        print "."
      end
    end

    private

      def add_ticket_fields
        1.times do |n|
          ticket_field = Desk::Ticket::Fields::CreatorService.new(
            ticket_fields[n],
            @organization
          ).run

          if ticket_field.invalid?
            raise ActiveRecord::RecordInvalid.new(ticket_field)
          end
        end
      end

      def create_a_comment!(ticket, author, parent_comment = nil, options = {})
        params = {
          info: Faker::Lorem.sentence,
          author:,
          message_id: random_message_id
        }.merge(options)

        if parent_comment
          params.merge! \
            created_at: parent_comment.created_at + 4.hours,
            in_reply_to_id: parent_comment.message_id
        end

        ticket.comments.create!(params)
      end

      def random_message_id
        SecureRandom.hex(10)
      end

      def ticket_fields
        [
          {
            organization_id: @organization.id,
            agent_label: "Customer Name",
            customer_label: "Your Name",
            is_required: true,
            kind: "text",
            display_order: 0,
            is_required_for_agent_when_submitting_form: false,
            is_shown_to_customer: true,
            is_editable_by_customer: true,
            is_required_for_customer_when_submitting_form: true,
            is_required_for_agent_when_closing_ticket: false
          }
        ]
      end

      def customers
        @_customers ||= SampleData::OrganizationCustomerSeeder.new(@organization).seed_customers
      end

      def agents
        @_agents ||= ["agent syndi", "agent oliver"].map { |name| create_agent!(name) }
      end

      def tags
        @_tags ||= TAG_NAMES.map do |name|
          Desk::Tag::TicketTag.create!(name:, organization:)
        end
      end

      def random_time(to, from = Time.current)
        Time.zone.at(random_in_range(from.to_f, to.to_f))
      end

      def random_in_range(from, to)
        rand * (to - from) + from
      end

      def create_agent!(name)
        first_name, last_name = name.split(" ")
        email = name.delete(" ").downcase + "@#{parameterize_organization_name}.com"

        organization.users.create!(
          email:,
          first_name:,
          last_name:,
          password: "welcome",
          role: organization.roles.find_by(name: Organization::AGENT_ROLE_NAME)
        )
      end

      def parameterize_organization_name
        @_parameterize_organization_name ||= organization.name.parameterize.underscore
      end

      def generate_survey_responses_for_tickets_with_status_resolved(resolved_ticket)
        resolved_ticket.survey_responses.create!(
          scale_choice: ::Desk::CustomerSatisfaction::ScaleChoice.all.sample,
          comment: survey_response_comments.sample)
      end

      def survey_response_comments
        [
          "The response was quick and timely by the agent.",
          "Would recommend!",
          "Agent resolved the ticket without fixing the issue :("
        ]
      end

      def subjects
        [
          "Not able to hide widget",
          "Widget is slow",
          "Email are not going through",
          "Can't get neetoDesk on my site with default hidden feature",
          "Fails to generate invoice",
          "Fails to generate Report",
          "Views required Hard Reset to update",
          "Unable to login neetoDesk",
          "Need tech support for Insight feature",
          "Unable to show a hidden widget",
          "Unable to generate invoice",
          "Unable to signup",
          "App crashes randomly",
          "Unable to view Reports",
          "Reports are generating incorrect data",
          "Need tech support for Reports",
          "Need help with Date widget",
          "Unable to set durations using date widget",
          "Randomly fails to send message replies",
          "Need tech support regarding settings",
          "Need tech support regarding Messages Reports",
          "Replies sent by agent loading incorrect data",
          "Table reload button not working",
          "Data is not sorting properly",
          "App crashes while creating new ticket sometimes",
          "Need tech support regarding First Response Time Report",
          "Messages are not being sent",
          "Unable to view replies to messages",
          "Fails to generate Resolved Tickets Report",
          "Unable to change Settings",
          "Need tech support regarding settings update",
          "Unable to save updated settings",
          "App crashes while accessing settings",
          "Need tech support regarding reports data",
          "Need tech support regarding tickets",
          "Tickets info is not being stored properly"
        ]
      end

      def agent_response
        [
          "We are looking into it",
          "Just give few more hours, we are running it through the required tech support"
        ]
      end

      def customer_response
        [
          "Thanks for looking into it",
          "Please respond as soon as possible"
        ]
      end

      def generate_agent_response(ticket, comment_number, in_response_to_comment, agent)
        info = agent_response[comment_number]
        created_at_lower_limit = in_response_to_comment.created_at
        generate_comment!(ticket, agent, info, in_response_to_comment.message_id, created_at_lower_limit)
      end

      def generate_customer_response(ticket, comment_number, in_response_to_comment, customer)
        info = customer_response[comment_number]
        created_at_lower_limit = in_response_to_comment.created_at
        generate_comment!(ticket, customer, info, in_response_to_comment.message_id, created_at_lower_limit)
      end

      def add_first_comment!(ticket, customer, ticket_subject)
        info = "We are having trouble. please check, #{ticket_subject}"
        generate_comment!(ticket, customer, info, random_message_id, ticket.created_at, comment_type: :description)
      end

      def generate_comment!(ticket, author, info, in_reply_to_id, created_at_lower_limit, options = {})
        created_at_upper_limit = if created_at_lower_limit == ticket.created_at
          created_at_lower_limit + 24.hours
        else
          created_at_lower_limit + 48.hours
        end

        created_at = random_time(created_at_upper_limit, created_at_lower_limit)
        params = {
          info:,
          author:,
          message_id: random_message_id,
          in_reply_to_id:,
          created_at:
        }.merge(options)
        ticket.comments.create!(params)
      end
  end
end
