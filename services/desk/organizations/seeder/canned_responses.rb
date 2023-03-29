# frozen_string_literal: true

class Desk::Organizations::Seeder::CannedResponses
  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  def process!
    organization.desk_macros.create!(canned_responses_params)
  end

  private

    def canned_responses_params
      [
        {
          name: "Feedback",
          description: "Thank you for your feedback.",
          actions_attributes: [
            {
              name: :add_reply,
              body: <<~HTML
                <div>Thank you for your feedback.</div>
                HTML
            }
          ],
          record_visibility_attributes: {
            visibility: :all_agents
          }
        },
        {
          name: "Glad it is solved",
          description: "We are glad that the issue is resolved.",
          actions_attributes: [
            {
              name: :add_reply,
              body: <<~HTML
                <div>We are glad that the issue is resolved. Please let us know if you have any other questions.</div>
                HTML
            }
          ],
          record_visibility_attributes: {
            visibility: :all_agents
          }
        },
        {
          name: "We are looking into the issue",
          description: nil,
          actions_attributes: [
            {
              name: :add_reply,
              body: <<~HTML
                <div>
                  We are looking into the issue. We need some more time to fully resolve it. <br>
                  Thank you for your patience.
                  <br><br>
                  We will get back to you as soon as we have more updates on this issue.
                </div>
                HTML
            }
          ],
          record_visibility_attributes: {
            visibility: :all_agents
          }
        }
      ]
    end
end
