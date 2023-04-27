# frozen_string_literal: true

module AuthorizationError
  extend ActiveSupport::Concern

  included do
    rescue_from Pundit::NotAuthorizedError, with: :authorization_error
    include Pundit::Authorization
  end

  def authorization_error
    # 403 Forbidden response
    respond_to do |format|
      format.html { render "/pages/access_denied", status: 403 }
      format.json { respond_with_error("Access Denied", 403) }
      format.csv { respond_with_error("Access Denied", 403) }
    end
  end
end
