# frozen_string_literal: true

class Desk::Server::OrganizationCreatorService < Desk::Server::BasicAuthRequestService
  def initialize(organization)
    @organization = organization
    super(api_path, request_params)
  end

  def process
    super
  end

  def self.process
    ::Organization.find_each do |organization|
      Desk::Server::OrganizationCreatorService.new(organization).process
    end
  end

  private

    attr_reader :organization

    def api_path
      app_secrets.routes[:auth_app][:basic][:organizations_api_path]
    end

    def request_params
      {
        organization: {
          name: organization.name,
          subdomain: organization.subdomain
        }
      }
    end
end
