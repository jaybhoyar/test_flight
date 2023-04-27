# frozen_string_literal: true

require "test_helper"

class Desk::Views::DeletionServiceTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @organization = @user.organization

    create_multiple_views
  end

  def test_deletion_service_success
    assert_equal 5, views.count
    assert_difference ["views.count"], -5 do
      @views_deletion_service = Desk::Views::DeletionService.new(views).process
    end

    assert_equal "Views have been successfully deleted", @views_deletion_service
    assert_equal 0, views.count
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
