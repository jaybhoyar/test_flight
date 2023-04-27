# frozen_string_literal: true

require "test_helper"

class I18n::LanguageTest < ActiveSupport::TestCase
  attr_reader :language

  def setup
    @language = I18n::Language.create(
      name: "Swedish",
      locale: "sw"
    )
  end

  def test_language_language_validity
    assert language.valid?
  end

  def test_language_name_should_be_present
    new_language = I18n::Language.create(
      locale: "ir"
    )

    assert_not new_language.valid?
    assert_equal ["can't be blank"], new_language.errors.messages[:name]
  end

  def test_language_locale_should_be_present
    new_language = I18n::Language.create(
      name: "Hebrew"
    )

    assert_not new_language.valid?
    assert_equal ["can't be blank"], new_language.errors.messages[:locale]
  end

  def test_language_name_is_unique
    new_language = I18n::Language.create(
      name: "Swedish",
      locale: "br"
    )

    assert_not new_language.valid?
    assert_equal ["has already been taken"], new_language.errors.messages[:name]
  end

  def test_language_locale_is_unique
    new_language = I18n::Language.create(
      name: "Tamil",
      locale: "sw"
    )

    assert_not new_language.valid?
    assert_equal ["has already been taken"], new_language.errors.messages[:locale]
  end
end
