# frozen_string_literal: true

class Desk::Users::FromOmniauthService
  include SSOHelpers

  attr_reader :organization, :user, :user_attributes, :options, :response, :status

  def initialize(auth, options = {})
    @organization = Organization.current
    @options = options
    @user_attributes = user_attributes_from_auth(auth)
    @user_attributes[:organization_id] = @organization.id
    @status = nil
    @response = {}
  end

  def process
    save_user
  end

  def success?
    status == :ok
  end

  private

    def user_attributes_from_auth(auth)
      attributes = {
        email: auth.info.email,
        first_name: auth.info.first_name,
        last_name: auth.info.last_name,
        provider: auth.provider,
        uid: auth.uid,
        profile_image_url: auth.info.image,
        date_format: auth.info.date_format
      }

      attributes[:time_zone] = auth.info.time_zone if auth.info.time_zone

      if auth.provider == :doorkeeper
        attributes.merge!(
          doorkeeper_access_token: auth.credentials.token,
          doorkeeper_refresh_token: auth.credentials.refresh_token,
          doorkeeper_token_expires_at: auth.credentials.expires_at
        )
      end

      attributes
    end

    def save_user
      ActiveRecord::Base.transaction do
        find_or_initialize
        user.assign_attributes(user_attributes.except(:email, :organization_id))

        if user.new_record?
          user.password = default_password
          user.skip_confirmation!
        end

        user.save!
        set_success_response
      rescue ActiveRecord::RecordInvalid => exception
        Rails.logger.info "organization user exception #{exception.record.inspect}"
        set_error_response(exception.record)
      end
    end

    def find_or_initialize
      @user = User.find_or_initialize_by(user_attributes.slice(:email, :organization_id))
    end

    def set_success_response
      @response = { notice: I18n.t("resource.save", resource_name: "User") }
      @status = :ok
    end

    def set_error_response(record)
      @response = { error: record.errors.full_messages.to_sentence }
      @status = :unprocessable_entity
    end
end
