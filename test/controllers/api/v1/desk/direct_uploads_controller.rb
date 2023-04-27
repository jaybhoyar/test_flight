# frozen_string_literal: true

class Api::V1::Desk::DirectUploadsController < ActiveStorage::DirectUploadsController
  skip_forgery_protection

  def image_upload
    blob = ActiveStorage::Blob.create_and_upload!(
      io: params[:blob],
      filename: params[:name],
      content_type: params[:content_type]
    )

    render json: { imageURL: url_for(blob) }
  end

  def destroy
    blob_id = get_blob_id

    if blob_id.blank?
      return render json: { notice: "Signature is invalid." }, status: :unprocessable_entity
    end

    blob = ActiveStorage::Blob.find(blob_id)
    blob.attachments.each do |attachment|
      # Touch the records to clear the cache
      attachment.record&.touch
      attachment.purge
    end
    blob&.purge
    render status: :ok, json: { notice: t("resource.delete", resource_name: "Attachment") }
  end

  private

    def get_blob_id
      ActiveStorage.verifier.verify(params[:id], purpose: :blob_id)
    rescue ActiveSupport::MessageVerifier::InvalidSignature => error
      nil
    end
end
