# frozen_string_literal: true

class Desk::Customers::FetchOrCreateService
  attr_reader :organization, :email, :name, :user

  def initialize(organization, email, name = nil)
    @organization = organization
    @email = email
    @name = name
  end

  def process
    find_user
    add_user_to_organization!

    user
  end

  private

    def find_user
      @user = @organization.users.unscoped.find_by(email: email.downcase)

      if @user.nil?
        find_user_with_email_contact_detail
      end
    end

    def user_within_correct_org?(user)
      user.organization == @organization
    end

    def find_user_with_email_contact_detail
      @user_with_alternate_email = EmailContactDetail.find_by(value: email.downcase)
      if @user_with_alternate_email.present? && user_within_correct_org?(@user_with_alternate_email)
        @user = @user_with_alternate_email.user
      end
    end

    def add_user_to_organization!
      if @user.blank?
        first_name, last_name = get_user_names

        @user = @organization.users.create!(
          skip_assign_role: true,
          skip_password_validation: true,
          email:,
          first_name:,
          last_name:,
          company_id:
        )

        @user.create_customer_detail
      end
    end

    def get_user_names
      if name.present?
        name_parts = name.split(" ")

        case name_parts.length
        when 1
          first_name = name_parts.first
        when 2
          first_name, last_name = name_parts
        else
          first_name = name_parts[0, name_parts.length - 1].join(" ")
          last_name = name_parts.last
        end
      else
        email_name_parts = email.split("@").first
        if email_name_parts.include?(".")
          email_name_parts = email_name_parts.split(".")
          first_name = email_name_parts.first.capitalize
          last_name = email_name_parts.last.capitalize
        else
          first_name = email_name_parts.capitalize
          last_name = nil
        end
      end

      [first_name, last_name]
    end

    def company_id
      Desk::Customers::CompanyFinderService
        .new(organization, email)
        .process&.id
    end
end
