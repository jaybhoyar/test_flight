# frozen_string_literal: true

class AttachmentService
  include Rails.application.routes.url_helpers

  attr_reader :attachment

  delegate_missing_to :attachment

  def initialize(attachment)
    @attachment = attachment
  end

  def path
    rails_blob_path(attachment, only_path: true)
  end

  def is_image
    attachment.blob.image?
  end

  def is_video
    attachment.blob.video?
  end

  def filename
    attachment.filename.sanitized
  end

  def extension
    attachment.filename.extension
  end

  def download_url
    rails_blob_url(attachment, disposition: "attachment", host:)
  end

  def signed_blob_id
    attachment.blob.signed_id
  end

  def size
    attachment.blob.byte_size
  end

  private

    def host
      Organization.current&.root_url || Rails.application.secrets.host
    end
end
