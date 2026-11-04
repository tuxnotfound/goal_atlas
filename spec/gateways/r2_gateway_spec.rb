require 'rails_helper'

RSpec.describe R2Gateway do
  let(:listing) do
    '<?xml version="1.0" encoding="UTF-8"?><ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">' \
      "<Name>backups</Name><KeyCount>2</KeyCount><MaxKeys>1000</MaxKeys><IsTruncated>false</IsTruncated>" \
      "<Contents><Key>goal_atlas/b.dump</Key></Contents><Contents><Key>goal_atlas/a.dump</Key></Contents></ListBucketResult>"
  end

  it "lists the keys under a prefix, sorted" do
    with_env(R2_TEST_SETTINGS) do
      stub_request(:get, %r{\Ahttps://r2\.test/backups\?.*prefix=goal_atlas}).to_return(body: listing)

      expect(described_class.keys("goal_atlas/")).to eq([ "goal_atlas/a.dump", "goal_atlas/b.dump" ])
    end
  end

  it "turns a refusal into Unauthorized" do
    with_env(R2_TEST_SETTINGS) do
      stub_request(:delete, "https://r2.test/backups/goal_atlas/a.dump")
        .to_return(status: 403, body: "<Error><Code>AccessDenied</Code><Message>Access Denied</Message></Error>")

      expect { described_class.remove("goal_atlas/a.dump") }.to raise_error(ApplicationGateway::Unauthorized)
    end
  end

  it "is configured only with all four settings" do
    with_env(R2_TEST_SETTINGS.merge("R2_BUCKET" => nil)) { expect(described_class).not_to be_configured }
    with_env(R2_TEST_SETTINGS) { expect(described_class).to be_configured }
  end
end
