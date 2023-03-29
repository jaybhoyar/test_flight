# frozen_string_literal: true

class Desk::Organizations::Seeder::AutomationRules
  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  def process!
    seed!
  end

  private

    def seed!
      organization.rules.create!(rules_params)
      organization.rules.create!(custom_rules_params)
    end

    def rules_params
      YAML.load_file("config/seed/automation_rules.yml")
    end

    def custom_rules_params
      default_business_hours = organization.business_hours.first

      {
        active: false,
        name: "[Notify] - Notify when ticket is created outside business hours",
        description: "Send an email to the requester when the ticket is created outside of business hours.",
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
                verb: "not_during",
                value: default_business_hours.id
              },
              {
                join_type: "and_operator",
                field: "channel",
                verb: "is_not",
                value: "twitter"
              }
            ]
          }
        ],
        actions_attributes: [
          {
            name: "email_to_requester",
            subject: 'We have received your request for the ticket #{{ticket.number}}!',
            body: <<~HTML
              <div>
              Hi {{ticket.requester.name}},<br><br>
              We have received your ticket {{ticket.number}}.<br><br>
              This email is sent out as the ticket is created outside of our business hours.<br>
              But be worry-free as we will take this the first thing when we start again.<br><br>
              Thank you,<br>
              Team {{ticket.organization.name}}
              </div>
              HTML
          }
        ]
      }
    end
end
