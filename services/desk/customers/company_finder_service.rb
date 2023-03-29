# frozen_string_literal: true

class Desk::Customers::CompanyFinderService
  attr_reader :organization, :email

  def initialize(organization, email)
    @organization = organization
    @email = email
  end

  def process
    company_domain = CompanyDomain.joins(:company)
      .where(company: { organization_id: organization.id })
      .where("company_domains.name ILIKE ?", "%#{email_domain}%")
      .first

    return company_domain.company if company_domain.present?
  end

  private

    def email_domain
      email.split("@").last.strip
    end
end
