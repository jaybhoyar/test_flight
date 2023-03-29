# frozen_string_literal: true

class Desk::Organizations::Users::CreatorService
  include SSOHelpers

  attr_reader :organization, :options, :inviter, :response, :user
  attr_accessor :errors, :status

  def initialize(organization, inviter, options = {})
    @organization = organization
    @inviter = inviter
    @options = options
  end

  def process
    find_user
    create_service_response
  end

  private

    def find_user
      @user = @organization.users.find_by(email: options[:email])
    end

    def create_service_response
      if @user.present?
        generate_existing_user_custom_error_message
      elsif add_user_to_organization_with_invitation_if_invited
        set_status_and_response
      end
    end

    def add_user_to_organization_with_invitation_if_invited
      User.transaction do
        @user = @organization.users.create! user_options
        if sso_enabled? && !@user.customer?
          inviter_service = Users::UserInviterService.new(inviter, user)
          inviter_service.process

          unless inviter_service.success?
            set_errors_and_status(inviter_service.response[:error])
            raise ActiveRecord::Rollback
          end
        end
        true
      rescue ActiveRecord::RecordInvalid => invalid
        set_errors_and_status(invalid.record.errors.full_messages.to_sentence)
        false
      end
    end

    def set_errors_and_status(message)
      @status = :unprocessable_entity
      @errors = message
    end

    def set_status_and_response
      @status = :ok
      @response = { notice: "Successfully added \'#{@user.name}\' as a new #{role_name}." }
    end

    def role_name
      @user.role_name || "customer"
    end

    def user_options
      {
        email: options[:email],
        organization_role_id: options[:organization_role_id],
        first_name: options[:first_name],
        last_name: options[:last_name],
        status: "invited",
        confirmed_at: Time.current,
        password: SecureRandom.alphanumeric(100),
        skip_password_validation: true
      }
        .merge(timezone_options)
    end

    def timezone_options
      if options[:time_zone_offset].present?
        offset = options[:time_zone_offset].to_i
        time_zone = ActiveSupport::TimeZone[-offset.minutes]
        return { time_zone: time_zone.name } if time_zone
      end
      {}
    end

    def generate_existing_user_custom_error_message
      error_message = "Email #{@user.email} already exists."
      set_errors_and_status(error_message)
    end
end
