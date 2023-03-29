# frozen_string_literal: true

class KeyPerformanceIndicatorsGeneratorService
  def process
    generate_data
  end

  private

    def generate_data
      {
        client_application_name: "Desk",
        organizations_data: generate_organizations_data
      }
    end

    def generate_organizations_data
      organizations_data = []

      Organization.in_batches do |organization_batch|
        organizations_batch_data = organization_batch.pluck(:id, :subdomain).map do |org_id, subdomain|
          {
            subdomain:,
            data: {
              unresolved_tickets_count: unresolved_tickets_count[org_id].to_i,
              tickets_count: tickets_count[org_id].to_i,
              companies_count: companies_count[org_id].to_i,
              users_count: users_count[org_id].to_i,
              notes_count: notes_count[org_id].to_i,
              tags_count: tags_count[org_id].to_i,
              tasks_count: tasks_count[org_id].to_i,
              desk_ticket_fields_count: desk_ticket_fields_count[org_id].to_i,
              automation_rules_count: automation_rules_count[org_id].to_i,
              customer_satisfaction_surveys_count: customer_satisfaction_surveys_count[org_id].to_i,
              business_hours_count: business_hours_count[org_id].to_i
            }
          }
        end
        organizations_data.concat organizations_batch_data
      end

      organizations_data
    end

    def unresolved_tickets_count
      @unresolved_tickets_count ||= Ticket.unresolved.group(:organization_id).count
    end

    def tickets_count
      @tickets_count ||= Ticket.group(:organization_id).count
    end

    def companies_count
      @companies_count ||= Company.group(:organization_id).count
    end

    def users_count
      @users_count ||= User.group(:organization_id).count
    end

    def notes_count
      @notes_count ||= User.joins(:notes).group(:organization_id).count
    end

    def tags_count
      @tags_count ||= Tag.group(:organization_id).count
    end

    def tasks_count
      @tasks_count ||= Ticket.joins(:tasks).group(:organization_id).count
    end

    def desk_ticket_fields_count
      @desk_ticket_fields_count ||= Organization.joins(:ticket_fields).group(:id).count
    end

    def automation_rules_count
      @automation_rules_count ||= Organization.joins(:rules).group(:organization_id).count
    end

    def customer_satisfaction_surveys_count
      @desk_customer_satisfaction_survey ||= Desk::CustomerSatisfaction::Survey.group(:organization_id).count
    end

    def business_hours_count
      @business_hours_count ||= Desk::BusinessHour.group(:organization_id).count
    end
end
