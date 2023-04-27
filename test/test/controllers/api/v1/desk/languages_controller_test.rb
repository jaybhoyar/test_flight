# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::LanguagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    I18n::Language.create(
      name: "Swedish",
      locale: "sw"
    )
  end

  def test_index
    languages = I18n::Language.all

    assert_equal 1, languages.count
  end
end
