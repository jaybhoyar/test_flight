# frozen_string_literal: true

# Usage: SampleDataLoaderService.new.run!

class SampleDataLoaderService
  def initialize
    firstnames = [
      "john", "jane", "daniel", "josefa", "jeremy", "hans", "paul",
      "kaylee", "stacee", "rosemary", "jamika", "sally"
    ]
    lastnames = [
      "feeney", "kuhlman", "gutkowski", "schiller", "langosh", "grady",
      "ferry", "kuvalis", "williamson", "newton", "slack"
    ]
    @agent_pool = firstnames.product(lastnames).shuffle
  end

  def add_prefix!
    SampleData::PrefixGenerator.new.run!
  end

  def run!
    add_prefix!
    sql_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil

    puts "Deleting existing data from tables..."
    delete_all_records_from_all_tables

    puts "Loading sample data..."
    [
      "create_permissions",
      "create_data_for_spinkart_organization",
      "create_data_for_campaigns",
      "create_delivery_window_data_for_campaigns",
      "create_ticket_fields",
      "create_automation_rules",
      "create_data_for_views"
    ].each do |method_name|
      puts method_name
      send(method_name)
    end

    ActiveRecord::Base.logger = sql_logger

    puts "Sample data loading completed."
  end

  def create_data_for_spinkart_organization
    org = Desk::Organizations::CreateService
      .new(Rails.application.secrets.organizations[:spinkart])
      .process

    Desk::Organizations::Seeder::Roles.new(org).process

    create_admins(org)
    create_agents(org)
    add_agents_to_groups(org)

    app_url = AppUrlCarrier.app_url

    SampleData::OrganizationTicketSeeder.new(org).seed_tickets
  end

  def create_admins(organization)
    default_admins = [
      {
        email: "oliver@example.com",
        first_name: "Oliver",
        last_name: "Smith",
        password: "welcome",
        confirmed_at: Time.current,
        role: organization.roles.find_by(name: Organization::ADMIN_ROLE_NAME)
      }
    ]

    organization.users.create!(default_admins)
  end

  def create_agents(organization)
    40.times do
      organization.users.create!(fetch_an_agent(organization))
    end
  end

  def fetch_an_agent(organization)
    first_name, last_name = @agent_pool.pop

    {
      email: "#{first_name}.#{last_name}@example.com",
      first_name: first_name.capitalize,
      last_name: last_name.capitalize,
      confirmed_at: Time.current,
      password: "welcome",
      role: organization.roles.find_by(name: Organization::AGENT_ROLE_NAME)
    }
  end

  def create_data_for_campaigns
    [
      {
        state: "Draft",
        message_type: "ongoing",
        title: "Forward company's support email",
        email_subject: "Forward your company's support email to neetoDesk",
        rule_attributes: {
          name: "Forward company's support email",
          description: "Forward your company's support email to neetoDesk",
          conditions_attributes: [
            {
              join_type: "and_operator",
              field: "created_at",
              verb: "any_time",
              value: nil
            }
          ]
        },
        email_content: <<~TEXT
          <div>It takes just 2 clicks to setup support email in neetoDesk.
          Follow along this guide https://help.groovehq.com/help/getting-your-emails-into-groove?utm_source=sequence&utm_medium=email&utm_campaign=the-easiest-thing-youll-do-today and you will getting support email in neetoDesk in minutes.
          Just reply to this email if you have any question.
          Cheers,
          - Nisha
          Customer Success Manager at neetoDesk</div>
          TEXT
      },

      {
        state: "Draft",
        message_type: "broadcast",
        title: "Terms of service update",
        email_subject: "We’re updating our Terms of Service",
        rule_attributes: {
          name: "Terms of service update",
          description: "We’re updating our Terms of Service",
          conditions_attributes: [
            {
              join_type: "and_operator",
              field: "created_at",
              verb: "any_time",
              value: nil
            }
          ]
        },
        email_content: <<~TEXT
          <div>
          Get to know our new Terms before they take effect on March 31, 2020
          - Rohit
          </div>
          TEXT
      },

      {
        state: "Draft",
        message_type: "ongoing",
        title: "Feedback",
        email_subject: "Send Feedback",
        rule_attributes: {
          name: "Feedback",
          description: "Send Feedback",
          conditions_attributes: [
            {
              join_type: "and_operator",
              field: "created_at",
              verb: "any_time",
              value: nil
            }
          ]
        },
        email_content: <<~TEXT
          <div>
          Tell us what you loved about us or what can we do better
          - Sahil
          </div>
          TEXT
      }
    ].each do |outbound_message|

      Organization.all.each do |organization|
        user = organization.users.where(role: organization.roles.find_by_name("Owner"))
        organization.outbound_messages.create!(outbound_message)
      end
    end
  end

  def create_delivery_window_data_for_campaigns
    Organization.all.each do |organization|

      organization.outbound_messages.each do |outbound_message|

        outbound_delivery_window_params =
        [
          {
            name: "All weekdays",
            time_zone: "Greenland",
            message: outbound_message,
            schedules_attributes: [
              {
                day: Outbound::DeliveryWindow::Schedule::DAYS_NAMES[0],
                from: Desk::Outbound::DeliveryWindowService::FROM_TIME - 1.hour,
                to: Desk::Outbound::DeliveryWindowService::TO_TIME - 2.hour,
                status: "active"
              },
              {
                day: Outbound::DeliveryWindow::Schedule::DAYS_NAMES[1],
                from: Desk::Outbound::DeliveryWindowService::FROM_TIME - 1.hour,
                to: Desk::Outbound::DeliveryWindowService::TO_TIME - 2.hour,
                status: "active"
              },
              {
                day: Outbound::DeliveryWindow::Schedule::DAYS_NAMES[2],
                from: Desk::Outbound::DeliveryWindowService::FROM_TIME - 1.hour,
                to: Desk::Outbound::DeliveryWindowService::TO_TIME - 2.hour,
                status: "active"
              },
              {
                day: Outbound::DeliveryWindow::Schedule::DAYS_NAMES[3],
                from: Desk::Outbound::DeliveryWindowService::FROM_TIME + 1.hour,
                to: Desk::Outbound::DeliveryWindowService::TO_TIME + 2.hour,
                status: "active"
              },
              {
                day: Outbound::DeliveryWindow::Schedule::DAYS_NAMES[4],
                from: Desk::Outbound::DeliveryWindowService::FROM_TIME - 1.hour,
                to: Desk::Outbound::DeliveryWindowService::TO_TIME - 2.hour,
                status: "active"
              },
              {
                day: Outbound::DeliveryWindow::Schedule::DAYS_NAMES[5],
                from: Desk::Outbound::DeliveryWindowService::FROM_TIME - 1.hour,
                to: Desk::Outbound::DeliveryWindowService::TO_TIME - 2.hour,
                status: "inactive"
              },
              {
                day: Outbound::DeliveryWindow::Schedule::DAYS_NAMES[6],
                from: Desk::Outbound::DeliveryWindowService::FROM_TIME - 1.hour,
                to: Desk::Outbound::DeliveryWindowService::TO_TIME - 2.hour,
                status: "inactive"
              }
            ]
          }
        ]

        Outbound::DeliveryWindow.create!(outbound_delivery_window_params)
      end
    end
  end

  def add_agents_to_groups(org)
    agents = org.users.where(role: org.roles.find_by_name("Agent"))
    org.groups.each do |group|
      group.users << agents.sample((3..6).to_a.sample)
    end
  end

  def create_ticket_fields
    Organization.all.each do |org|
      [
        {
          agent_label: "Order Number",
          customer_label: "Order Number",
          kind: "text",
          is_required_for_agent_when_closing_ticket: true
        },
        {
          agent_label: "Tracking Number",
          customer_label: "Tracking Number",
          kind: "text",
          is_required_for_agent_when_closing_ticket: false
        }
      ].each do |ticket_field|
        org.ticket_fields.create!(ticket_field)
      end
    end
  end

  def create_automation_rules
    rules_params = [
      {
        name: "Auto-assign tickets to agent with less work load",
        description: "Automatically assign tickets to the agents who have less work load (Load Balanced)",
        events_attributes: [
          {
            name: "created"
          }
        ],
        condition_groups_attributes: [
          {
            join_type: "and_operator",
            conditions_join_type: "and_operator",
            conditions_attributes: [
              {
                join_type: "and_operator",
                field: "created_at",
                verb: "any_time",
                value: ""
              }
            ]
          }
        ],
        actions_attributes: [
          {
            name: "assign_agent_load_balanced"
          }
        ]
      },
      {
        name: "Notify payment gateway service of a failure ticket",
        description: 'Send an email to Payment gateway of the tickets which have "payment failure" in the subject.',
        events_attributes: [
          {
            name: "created"
          }
        ],
        condition_groups_attributes: [
          {
            join_type: "and_operator",
            conditions_join_type: "and_operator",
            conditions_attributes: [
              {
                join_type: "and_operator",
                field: "subject",
                verb: "contains",
                value: "payment failure"
              }
            ]
          }
        ],
        actions_attributes: [
          {
            name: "email_to",
            value: "payments@example.com, admin@example.com",
            subject: "We have received a ticket for payment failure!",
            body: <<~TEXT
              <div>
              Hi,<br><br>
              We have received a ticket for payment failure.<br>
              Here are details:<br>
              URL: {{ticket.url}}<br>
              Subject: {{ticket.subject}}<br>
              Category: {{ticket.category}}<br><br>
              Thanks,<br>
              Team {{ticket.organization.name}}
              </div>
              TEXT
          }
        ]
      },
      {
        name: "Add a note when the ticket is waiting on customer for 5 days",
        description: "Add a reminder note for customer when the ticket is in waiting for customer for more than 5 days",
        condition_groups_attributes: [
          {
            join_type: "and_operator",
            conditions_join_type: "and_operator",
            conditions_attributes: [
              {
                join_type: "and_operator",
                field: "status.hours.waiting_on_customer",
                verb: "greater_than",
                value: "120",
                kind: "time_based"
              }
            ]
          }
        ],
        actions_attributes: [
          {
            name: "add_note",
            body: <<~TEXT
              <div>
              Hi {{ticket.requester.name}},<br><br>
              This is a reminder note to let you know that this issue is open as we are expecting your response for the same.<br>
              Please get back to us in due time to resolve this issue quickly.<br><br>
              Thanks,<br>
              Team {{ticket.organization.name}}
              </div>
              TEXT
          }
        ]
      },
      {
        name: "Notify customer about the dependancy",
        description: "Send an email to customers when a ticket is assigned to them.",
        events_attributes: [
          {
            name: "status_changed"
          }
        ],
        condition_groups_attributes: [
          {
            join_type: "and_operator",
            conditions_join_type: "and_operator",
            conditions_attributes: [
              {
                join_type: "and_operator",
                field: "status",
                verb: "is",
                value: "waiting_on_customer"
              }
            ]
          }
        ],
        actions_attributes: [
          {
            name: "email_to_requester",
            subject: "We are waiting for your response on a ticket!",
            body: <<~TEXT
              <div>
              Hi {{ticket.requester.name}},<br><br>
              We need your action on this ticket so that we could resolve it at earliest.<br>
              URL: {{ticket.url}}<br><br>
              Thanks,<br>
              Team {{ticket.organization.name}}
              </div>
              TEXT
          }
        ]
      }
    ]

    Organization.where(subdomain: ["app", "spinkart"]) do |organization|
      agent_1 = organization.agents.first
      agent_2 = organization.agents.second

      billing_tag = organization.tags.where("name like '%Billing%'").first
      urgent_tag = organization.tags.where("name like '%Urgent%'").first

      other_rule_params = [
        {
          name: "Automatically assign #billing tag",
          description: 'Assign billing tag to the tickets containing "refund" or "payment" in the subject.',
          events_attributes: [
            {
              name: "created"
            }
          ],
          condition_groups_attributes: [
            {
              join_type: "and_operator",
              conditions_join_type: "or_operator",
              conditions_attributes: [
                {
                  join_type: "or_operator",
                  field: "subject",
                  verb: "contains",
                  value: "refund"
                },
                {
                  join_type: "or_operator",
                  field: "subject",
                  verb: "contains",
                  value: "payment"
                }
              ]
            }
          ],
          actions_attributes: [
            {
              name: "set_tags",
              tag_ids: [billing_tag.id]
            }
          ]
        },
        {
          name: "Assign tag #urgent",
          description: "Assign #urgent when comments are added with 'urgent' or 'immediate' keywords.",
          events_attributes: [
            {
              name: "reply_added"
            },
            {
              name: "note_added"
            }
          ],
          condition_groups_attributes: [
            {
              join_type: "and_operator",
              conditions_join_type: "or_operator",
              conditions_attributes: [
                {
                  join_type: "or_operator",
                  field: "ticket.comments.description",
                  verb: "contains",
                  value: "urgent"
                },
                {
                  join_type: "or_operator",
                  field: "ticket.comments.description",
                  verb: "contains",
                  value: "immediate"
                }
              ]
            }
          ],
          actions_attributes: [
            {
              name: "add_tags",
              tag_ids: [urgent_tag.id]
            }
          ]
        },
        {
          name: "Assign urgent tickets to Ethan Hunt",
          description: "
            Urgent issues are handled by Ethan Hunt;
            Assign tickets with urgent priority to Ethan and send him an email.",
          events_attributes: [
            {
              name: "created"
            }
          ],
          condition_groups_attributes: [
            {
              join_type: "and_operator",
              conditions_join_type: "and_operator",
              conditions_attributes: [
                {
                  join_type: "and_operator",
                  field: "priority",
                  verb: "is",
                  value: "3"
                }
              ]
            }
          ],
          actions_attributes: [
            {
              name: "assign_agent",
              actionable_id: agent_1.id,
              actionable_type: "User"
            },
            {
              name: "email_to_agent",
              actionable_id: agent_1.id,
              actionable_type: "User",
              subject: 'We have received a new URGENT ticket #{{ticket.number}}!',
              body: <<~TEXT
                <div>
                Hi Ethan,<br><br>
                We have a new urgent ticket for you, please take actions on it in due time.<br><br>
                Here are the details about your new ticket:<br>
                ID: {{ticket.id}}<br>
                Number: {{ticket.number}}<br>
                URL: {{ticket.url}}<br><br>
                Thanks,<br>
                Team {{ticket.organization.name}}
                </div>
                TEXT
            }
          ]
        },
        {
          name: "Notify about a bad feedback by user",
          description: "Send a notification to Jason Bourne when user responds with a 'Not Good' feedback.",
          events_attributes: [
            {
              name: "feedback_received"
            }
          ],
          condition_groups_attributes: [
            {
              join_type: "and_operator",
              conditions_join_type: "and_operator",
              conditions_attributes: [
                {
                  join_type: "and_operator",
                  field: "feedback",
                  verb: "is",
                  value: "unhappy"
                }
              ]
            }
          ],
          actions_attributes: [
            {
              name: "email_to_agent",
              actionable_id: agent_2.id,
              actionable_type: "User",
              subject: "We have received a not good feedback from a customer!",
              body: <<~TEXT
                <div>
                Hi Jason,<br><br>
                We have received a feedback which is "Not Good". Please follow the details below:<br>
                Name: {{ticket.requester.name}}<br>
                Email: {{ticket.requester.email}}<br>
                Ticket: {{ticket.url}}<br><br>
                Please take necessary actions.<br><br>
                Thanks,<br>
                Team {{ticket.organization.name}}
                </div>
                TEXT
            }
          ]
        },
        {
          name: "Automatically remove ticket assignment from agents who are out of office",
          description: "Remove ticket assignment for agents who are not available",
          condition_groups_attributes: [
            {
              join_type: "and_operator",
              conditions_join_type: "and_operator",
              conditions_attributes: [
                {
                  join_type: "and_operator",
                  field: "agent.available_for_desk",
                  verb: "is",
                  value: "false"
                }
              ]
            }
          ],
          actions_attributes: [
            { name: "remove_assigned_agent" }
          ]
        }
      ]
      organization.rules.create!(rules_params)
      organization.rules.create!(other_rule_params)
    end
  end

  def create_data_for_views
    Organization.all.each do |org|
      creator = org.users.first

      [
        {
          title: "High Priority Tickets",
          description: nil,
          status: "active",
          record_visibility_attributes: {
            creator_id: creator.id,
            visibility: "all_agents"
          },
          rule_attributes: {
            name: "High Priority Tickets",
            organization_id: org.id,
            description: nil,
            conditions_attributes: [{
              join_type: "and_operator",
              field: "priority",
              verb: "is",
              value: 2
            }]
          }
        },
        {
          title: "All Twitter Tickets",
          description: nil,
          status: "active",
          record_visibility_attributes: {
            creator_id: creator.id,
            visibility: "all_agents"
          },
          rule_attributes: {
            name: "All Twitter Tickets",
            organization_id: org.id,
            description: nil,
            conditions_attributes: [{
              join_type: "and_operator",
              field: "channel",
              verb: "is",
              value: "twitter"
            }]
          }
        },
        {
          title: "All Chat Tickets",
          description: nil,
          status: "active",
          record_visibility_attributes: {
            creator_id: creator.id,
            visibility: "all_agents"
          },
          rule_attributes: {
            name: "All Twitter Tickets",
            organization_id: org.id,
            description: nil,
            conditions_attributes: [{
              join_type: "and_operator",
              field: "channel",
              verb: "is",
              value: "chat"
            }]
          }
        }
      ].each do |view|
        org.views.create!(view)
      end
    end
  end

  def create_permissions
    PermissionSeederService.new.process
  end

  def delete_all_records_from_all_tables
    DatabaseCleaner.clean_with :truncation
  end
end
