require 'rails_helper'

RSpec.describe "Api::V1::Me", type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:application) { create(:doorkeeper_application) }
  let(:token) { create(:doorkeeper_access_token, application: application, resource_owner_id: user.id) }

  describe "GET /api/v1/me" do
    context "with valid access token" do
      it "returns the current user as JSON" do
        get "/api/v1/me", headers: { "Authorization" => "Bearer #{token.token}" }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(user.id)
        expect(json["email"]).to eq(user.email)
      end
    end

    context "without access token" do
      it "returns unauthorized" do
        get "/api/v1/me"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
