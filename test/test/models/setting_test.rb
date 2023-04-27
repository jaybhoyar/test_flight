# frozen_string_literal: true

require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "default custom_authentication value to be false" do
    setting = create(:setting, custom_authentication: true)
    assert setting.custom_authentication
  end

  test "default automatic_redaction value to be true" do
    setting = create(:setting, custom_authentication: true)
    assert setting.automatic_redaction
  end
end
