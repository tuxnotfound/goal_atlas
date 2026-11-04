require 'rails_helper'

RSpec.describe Backups::RunService do
  let(:empty_listing) do
    '<?xml version="1.0" encoding="UTF-8"?><ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">' \
      "<Name>backups</Name><KeyCount>0</KeyCount><MaxKeys>1000</MaxKeys><IsTruncated>false</IsTruncated></ListBucketResult>"
  end

  it "uploads a pg_dump of the database and leaves no copy behind" do
    with_env(R2_TEST_SETTINGS) do
      upload = stub_request(:put, %r{\Ahttps://r2\.test/backups/goal_atlas/test/test-\d{8}-\d{4}\.dump\z})
      stub_request(:get, %r{\Ahttps://r2\.test/backups\?.*list-type=2}).to_return(body: empty_listing)
      service = described_class.new

      expect(service.call).to be_truthy
      expect(upload).to have_been_requested
      expect(service.key).to start_with("goal_atlas/test/")
      expect(Dir.glob(Rails.root.join("tmp/test-*.dump"))).to be_empty
    end
  end

  it "refuses to run without R2" do
    with_env(R2_TEST_SETTINGS.transform_values { nil }) do
      service = described_class.new

      expect(service.call).to be_falsey
      expect(service.errors[:base]).to include("R2 is not configured, so nothing would leave the box")
    end
  end
end
