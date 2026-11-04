require 'rails_helper'

RSpec.describe Backups::SyncStorageService do
  def listing(entries)
    contents = entries.map { |key, size| "<Contents><Key>#{key}</Key><Size>#{size}</Size></Contents>" }.join
    '<?xml version="1.0" encoding="UTF-8"?><ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">' \
      "<Name>backups</Name><KeyCount>#{entries.size}</KeyCount><MaxKeys>1000</MaxKeys>" \
      "<IsTruncated>false</IsTruncated>#{contents}</ListBucketResult>"
  end

  def stub_listing(entries)
    stub_request(:get, %r{\Ahttps://r2\.test/backups\?.*list-type=2}).to_return(body: listing(entries))
  end

  def write(name, body)
    path = @root.join(name)
    path.dirname.mkpath
    path.write(body)
  end

  let(:prefix) { "goal_atlas/storage/test" }
  let(:base_url) { "https://r2.test/backups/#{prefix}" }

  around do |example|
    Dir.mktmpdir do |dir|
      @root = Pathname(dir)
      with_env(R2_TEST_SETTINGS) { example.run }
    end
  end

  before { stub_const("Backups::SyncStorageService::ROOT", @root) }

  it "uploads only the files R2 lacks, nested ones included" do
    write("stylized_portraits/messi_1.png", "old")
    write("stylized_portraits/mbappe_2.png", "new")
    stub_listing("#{prefix}/stylized_portraits/messi_1.png" => 3)
    upload = stub_request(:put, "#{base_url}/stylized_portraits/mbappe_2.png")
    service = described_class.new

    expect(service.call).to be_truthy
    expect(upload).to have_been_requested
    expect(a_request(:put, "#{base_url}/stylized_portraits/messi_1.png")).not_to have_been_made
    expect(service.uploaded).to eq(1)
  end

  it "uploads a file again when its size differs, which heals a partial copy" do
    write("stylized_portraits/messi_1.png", "complete")
    stub_listing("#{prefix}/stylized_portraits/messi_1.png" => 3)
    upload = stub_request(:put, "#{base_url}/stylized_portraits/messi_1.png")

    described_class.new.call

    expect(upload).to have_been_requested
  end

  it "keeps in R2 a file the volume no longer has" do
    stub_listing("#{prefix}/stylized_portraits/deleted_1.png" => 3)

    expect(described_class.new.call).to be_truthy
    expect(a_request(:delete, /r2\.test/)).not_to have_been_made
  end

  it "stays out of the prefix the database backup prunes" do
    expect(described_class::PREFIX).not_to start_with(Backups::RunService::PREFIX)
  end

  it "raises when R2 refuses an upload, so the job fails where it can be seen" do
    write("stylized_portraits/messi_1.png", "new")
    stub_listing({})
    stub_request(:put, "#{base_url}/stylized_portraits/messi_1.png")
      .to_return(status: 403, body: "<Error><Code>AccessDenied</Code><Message>Access Denied</Message></Error>")

    expect { described_class.new.call }.to raise_error(ApplicationGateway::Unauthorized)
  end

  it "refuses to run without R2" do
    with_env(R2_TEST_SETTINGS.transform_values { nil }) do
      service = described_class.new

      expect(service.call).to be_falsey
      expect(service.errors[:base]).to include("R2 is not configured, so nothing would leave the box")
    end
  end
end
