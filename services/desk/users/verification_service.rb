# frozen_string_literal: true

class Desk::Users::VerificationService
  attr_accessor :org_user, :organization, :email_domain, :email, :subdomain, :errors

  def initialize(email, subdomain)
    @email = email
    @subdomain = subdomain
    @email_domain = email.split("@").last
    @errors = []
  end

  def process
    @organization = Organization.find_by(subdomain:)
    @org_user = organization.users.find_by(email:)

    if org_user && !org_user.active_for_authentication?
      @errors.push(error_message)
    end
  end

  private

    def error_message
      if org_user.blank?
        "Incorrect email or password"
      elsif !org_user.active?
        I18n.t("devise.failure.deactivated")
      else
        I18n.t("devise.failure.#{org_user.unauthenticated_message}")
      end
    end
end
