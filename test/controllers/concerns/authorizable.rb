# frozen_string_literal: true

module Authorizable
  extend ActiveSupport::Concern

  included do
    def ensure_access_to_view_tickets!
      can?("desk.manage_own_tickets", "desk.view_tickets", "desk.reply_add_note_to_tickets", "desk.manage_tickets")
    end

    def ensure_access_to_manage_tickets!
      can?("desk.manage_own_tickets", "desk.manage_tickets")
    end

    def ensure_access_to_create_tickets!
      can? "desk.manage_tickets"
    end

    def ensure_access_to_view_customer_details!
      can?("customer.view_customer_details", "customer.manage_customer_details")
    end

    def ensure_access_to_manage_customer_details!
      can? "customer.manage_customer_details"
    end

    def ensure_access_to_view_reports!
      can?("reports.view_reports", "reports.manage_reports")
    end

    def ensure_access_to_manage_reports!
      can? "reports.manage_reports"
    end

    def ensure_access_to_manage_agents!
      can? "agents.manage_agent_details"
    end

    def ensure_access_to_manage_companies!
      can? "admin.manage_companies"
    end

    def ensure_access_to_manage_customer_tags!
      can? "admin.manage_customer_tags"
    end

    def ensure_access_to_manage_ticket_tags!
      can? "admin.manage_ticket_tags"
    end

    def ensure_access_to_manage_automation_rules!
      can? "admin.manage_automation_rules"
    end

    def ensure_access_to_manage_desk_canned_responses!
      can? "admin.manage_canned_responses"
    end

    def ensure_access_to_manage_ticket_fields!
      can? "admin.manage_ticket_fields"
    end

    def ensure_access_to_manage_groups!
      can? "admin.manage_groups"
    end

    def ensure_access_to_manage_roles!
      can? "admin.manage_roles"
    end

    def ensure_access_to_manage_organization_settings!
      can? "admin.manage_organization_settings"
    end

    private

      def can?(*permissions)
        if current_user && current_user.has_permission?(permissions)
          true
        else
          respond_to do |format|
            format.json { head :forbidden, content_type: "text/html" }
            format.html { redirect_to main_app.root_url, notice: exception.message }
            format.js { head :forbidden, content_type: "text/html" }
          end
        end
      end
  end
end
