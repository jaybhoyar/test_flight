# frozen_string_literal: true

class Desk::Organizations::Seeder::Roles
  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  def process
    roles_options.each do |attrs|
      role = ::OrganizationRole.find_or_initialize_by(name: attrs[:name], organization_id: @organization.id)
      role.assign_attributes attrs
      role.permissions = role.name == "Admin" ? Permission.all : permissions_accessible_to_agents

      role.save
    end
  end

  private

    def roles_options
      [
        {
          name: "Admin",
          description: "This role applies to the organization admin.",
          kind: "system",
          organization_id: organization.id
        },
        {
          name: "Agent",
          description: "This role applies to all the organization agents except the admin.",
          kind: "system",
          organization_id: organization.id
        }
      ]
    end

    def permissions_accessible_to_agents
      @_agent_permissions ||= Permission.where.not(category: ["Agents", "Settings"])
    end

    def all_permissions
      @_all_permissions ||= Permission.all
    end
end
