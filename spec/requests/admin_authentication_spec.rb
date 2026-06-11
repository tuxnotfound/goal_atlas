require 'rails_helper'

RSpec.describe "Admin authentication", type: :request do
  let(:admin)     { User.create!(email_address: "admin@test.local", password: "secret-pass-123", admin: true) }
  let(:non_admin) { User.create!(email_address: "user@test.local",  password: "secret-pass-123", admin: false) }

  def sign_in(user, password: "secret-pass-123")
    post "/session", params: { email_address: user.email_address, password: password }
  end

  describe "unauthenticated requests" do
    it "leaves the public site open" do
      get "/"
      expect(response).to have_http_status(:ok)
    end

    it "redirects /admin to the login page" do
      get "/admin"
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "authenticated non-admin" do
    it "is bounced from /admin back to login" do
      sign_in(non_admin)
      get "/admin"
      expect(response).to redirect_to(new_session_path)
      follow_redirect!
      expect(flash[:alert]).to match(/admin/i)
    end
  end

  describe "authenticated admin" do
    it "can reach /admin" do
      sign_in(admin)
      get "/admin"
      expect(response).to have_http_status(:ok)
    end
  end
end
