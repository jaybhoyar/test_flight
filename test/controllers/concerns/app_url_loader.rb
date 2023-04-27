# frozen_string_literal: true

module AppUrlLoader
  extend ActiveSupport::Concern

  included do
    before_action :load_app_url
  end

  def load_app_url
    @app_url = AppUrlCarrier.app_url(request)
  end
end
