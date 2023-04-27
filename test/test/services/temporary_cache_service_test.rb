# frozen_string_literal: true

require "test_helper"
class TemporaryCacheServiceTest < ActiveSupport::TestCase
  def setup
    @user = create :user
    @org_user = User.new(email: "oliver@example.com")
  end

  def test_set_user
    ott = TemporaryCacheService.new.set(@user)
    assert ott.is_a?(String)
  end

  def test_get_user
    ott = TemporaryCacheService.new.set(@user)
    assert_equal @user, TemporaryCacheService.new.get(ott)
  end

  def test_set_active_record_user_object
    ott = TemporaryCacheService.new.set(@org_user)
    assert ott.is_a?(String)
  end

  def test_get_active_record_user_object
    ott = TemporaryCacheService.new.set(@org_user)
    assert_equal @org_user.email, TemporaryCacheService.new.get(ott).email
  end
end
