require 'rails_helper'

RSpec.describe "Portraits", type: :request do
  let(:storage_dir) { Rails.root.join("storage", StylizedPortrait::STORAGE_DIR) }
  let(:filename)    { "test-portrait_#{SecureRandom.hex(4)}.png" }
  let(:path)        { storage_dir.join(filename) }

  before do
    FileUtils.mkdir_p(storage_dir)
    File.binwrite(path, "\x89PNG\r\n\x1a\n" + "test bytes")
  end

  after { File.delete(path) if File.exist?(path) }

  it "serves the PNG with 200 + image/png content-type" do
    get "/portraits/#{filename}"
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/png")
    expect(response.body.bytesize).to be > 0
  end

  it "404s when the file is missing on disk" do
    get "/portraits/missing-#{SecureRandom.hex(4)}.png"
    expect(response).to have_http_status(:not_found)
  end

  it "404s for filenames with uppercase or unexpected characters" do
    get "/portraits/EVIL.PNG"
    expect(response).to have_http_status(:not_found)
  end

  it "rejects path traversal attempts via the route constraint" do
    get "/portraits/..%2Fconfig%2Fdatabase.yml"
    expect(response.status).to be_in([404])
  end
end
