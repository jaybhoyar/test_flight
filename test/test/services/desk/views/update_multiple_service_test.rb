# frozen_string_literal: true

require "test_helper"

class Desk::Views::UpdateMultipleServiceTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @organization = @user.organization

    create_multiple_views
  end

  def test_process_success
    assert_equal 5, views.where(status: "active").count
    assert_equal 0, views.where(status: "inactive").count

    response = Desk::Views::UpdateMultipleService.new(views, { status: "inactive" }).process
    assert_equal "Views have been successfully deactivated.", response

    assert_equal 0, views.where(status: "active").count
    assert_equal views.count, views.where(status: "inactive").count

    response = Desk::Views::UpdateMultipleService.new(views, { status: "active" }).process
    assert_equal "Views have been successfully activated.", response

    assert_equal 5, views.where(status: "active").count
    assert_equal 0, views.where(status: "inactive").count
  end

  private

    def create_multiple_views
      5.times do
        view = create(:view, title: Faker::Lorem.sentence, organization: @organization)
        view.creator = @user
        view.save!
      end
    end

    def views
      @organization.views.all
    end
end
