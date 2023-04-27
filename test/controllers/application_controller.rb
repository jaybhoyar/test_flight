# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include AppUrlLoader
  include AuthorizationError
  include ErrorHandlers
  include LoadUser
  include SSOHelpers
end
