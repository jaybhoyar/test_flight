# frozen_string_literal: true

module LoadUser
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user

    alias_method :pundit_user, :current_user
  end

  def set_current_user
    User.current = current_user
  end
end
