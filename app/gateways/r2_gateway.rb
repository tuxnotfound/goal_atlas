# Cloudflare R2 through its S3 API: where the nightly copies of the database and of storage/ go. The AWS SDK
# makes the calls; this class keeps them in one place, with timeouts, and turns SDK errors into
# the gateway errors every caller already knows.
class R2Gateway < ApplicationGateway
  SETTINGS = %w[R2_ENDPOINT R2_BUCKET R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY].freeze

  def self.configured? = SETTINGS.all? { ENV[it].present? }

  def self.upload(key, io)
    call_r2 { client.put_object(bucket:, key:, body: io, content_type: "application/octet-stream") }
    key
  end

  def self.keys(prefix) = sizes(prefix).keys.sort

  # Key to size in bytes. Walks every page, because one listing stops at 1,000 keys.
  def self.sizes(prefix)
    call_r2 { client.list_objects_v2(bucket:, prefix:).flat_map(&:contents).to_h { [ it.key, it.size ] } }
  end

  def self.remove(key)
    call_r2 { client.delete_object(bucket:, key:) }
    key
  end

  def self.call_r2
    yield
  rescue Seahorse::Client::NetworkingError => error
    raise ConnectionFailed, "R2: #{error.message}"
  rescue Aws::S3::Errors::ServiceError => error
    raise error_class_for(error.context.http_response.status_code).new("R2: #{error.message}",
      status: error.context.http_response.status_code)
  end

  def self.client
    require "aws-sdk-s3"
    Aws::S3::Client.new(
      endpoint: ENV.fetch("R2_ENDPOINT"), region: "auto", force_path_style: true,
      access_key_id: ENV.fetch("R2_ACCESS_KEY_ID"), secret_access_key: ENV.fetch("R2_SECRET_ACCESS_KEY"),
      http_open_timeout: OPEN_TIMEOUT, http_read_timeout: READ_TIMEOUT
    )
  end

  def self.bucket = ENV.fetch("R2_BUCKET")

  private_class_method :call_r2, :client, :bucket
end
