# frozen_string_literal: true

class Api::V1::Desk::LanguagesController < ApplicationController
  def index
    @languages = I18nData.languages
  end
end
