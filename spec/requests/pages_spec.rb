require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /about" do
    it "renders the about page" do
      get about_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("About The Goal Atlas")
    end
  end

  describe "GET /privacy" do
    it "renders the privacy policy with the required AdSense advertising disclosures" do
      get privacy_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Privacy Policy")
      # Google requires the third-party advertising-cookie disclosure and an opt-out link.
      expect(response.body).to include("Third-party vendors, including Google, use cookies")
      expect(response.body).to include("https://www.google.com/settings/ads")
    end
  end

  describe "GET /contact" do
    it "renders the contact page with the contact email" do
      get contact_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Contact")
      expect(response.body).to include("tuxnotfound@cioga.eu")
    end
  end

  describe "GET /sitemap.xml" do
    it "lists the new informational pages" do
      get sitemap_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(about_url)
      expect(response.body).to include(privacy_url)
      expect(response.body).to include(contact_url)
    end
  end
end
