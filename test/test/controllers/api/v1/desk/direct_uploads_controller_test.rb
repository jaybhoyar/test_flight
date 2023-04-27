# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::DirectUploadsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create :organization
    host! test_domain(@organization.subdomain)
  end

  def test_destroy_with_invalid_signed_id
    delete "#{api_v1_desk_direct_uploads_url}/invalid_signed_id"
    assert_response :unprocessable_entity
  end

  def test_destroy_with_valid_signed_id
    signed_id = do_fake_direct_upload
    assert_difference "ActiveStorage::Blob.count", -1 do
      delete "#{api_v1_desk_direct_uploads_url}/#{signed_id}"
    end
    assert_response :ok
  end

  private

    def do_fake_direct_upload
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("random text"), filename: "random.txt")
      blob.signed_id
    end
end
