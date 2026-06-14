require 'rails_helper'

RSpec.describe "Llms", type: :request do
  describe "GET /llms.txt" do
    it "renders the llms.txt summary" do
      create(:tournament, :wc_2022,
             winner_team: create(:team, name: "Argentina"))

      get llms_path

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to start_with("text/plain")
      expect(response.body).to include("# The Goal Atlas")
      expect(response.body).to include("FIFA World Cup 2022")
      expect(response.body).to include("Qatar")
      expect(response.body).to include("won by Argentina")
    end
  end
end
