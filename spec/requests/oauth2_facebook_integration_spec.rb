require 'rails_helper'

RSpec.describe "OAuth2 Facebook Integration", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:tenant) { create(:tenant, tenant_mode: :single) }
  let(:application) { create(:doorkeeper_application, redirect_uri: 'https://example.com/callback') }
  let(:facebook_user) do
    create(:user, :facebook_oauth,
           email: 'facebook_user@example.com',
           password: 'generated_password_123',
           tenant: tenant)
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_tenant).and_return(tenant)
  end

  describe "Facebook OAuth users with OAuth2/Doorkeeper" do
    context "when Facebook user requests access token" do
      it "allows Facebook OAuth users to obtain access tokens via password grant" do
        post "/oauth/token", params: {
          grant_type: 'password',
          username: facebook_user.email,
          password: facebook_user.password,
          client_id: application.uid,
          client_secret: application.secret
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json).to include('access_token', 'token_type', 'expires_in', 'scope')
        expect(json['token_type']).to eq('Bearer')
      end

      it "allows Facebook OAuth users to obtain access tokens with custom scopes" do
        post "/oauth/token", params: {
          grant_type: 'password',
          username: facebook_user.email,
          password: facebook_user.password,
          client_id: application.uid,
          client_secret: application.secret,
          scope: 'read write'
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['scope']).to eq('read write')
      end
    end

    context "when Facebook user accesses protected API" do
      let(:token) do
        create(:doorkeeper_access_token, 
               application: application, 
               resource_owner_id: facebook_user.id)
      end
      let(:headers) { { "Authorization" => "Bearer #{token.token}", "ACCEPT" => "application/json" } }

      it "allows Facebook OAuth users to access protected endpoints" do
        get "/api/v1/me", headers: headers
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(facebook_user.id)
        expect(json["email"]).to eq(facebook_user.email)
      end

      it "includes OAuth provider information in user data" do
        get "/api/v1/users/#{facebook_user.id}", headers: headers
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["provider"]).to eq('facebook')
        expect(json["uid"]).to eq(facebook_user.uid)
        expect(json["name"]).to eq(facebook_user.name)
        expect(json["image"]).to eq(facebook_user.image)
      end
    end
  end

  describe "Facebook OAuth user creation and OAuth2 integration" do
    let(:facebook_uid) { "123456789012345" }
    let(:facebook_email) { "new_facebook_user@example.com" }

    it "creates Facebook OAuth user and allows OAuth2 access" do
      # Mock OmniAuth response for new user
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new({
        provider: 'facebook',
        uid: facebook_uid,
        info: {
          email: facebook_email,
          name: 'New Facebook User',
          image: 'https://graph.facebook.com/123456789012345/picture'
        }
      })

      # Simulate Facebook OAuth callback
      get "/users/auth/facebook/callback"
      
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(users_my_page_path)

      # Find the created user
      user = User.find_by(provider: 'facebook', uid: facebook_uid)
      expect(user).to be_present
      expect(user.email).to eq(facebook_email)

      # For testing, we'll create a new user with a known password
      test_user = create(:user, :facebook_oauth, 
                        email: 'test_oauth_user@example.com', 
                        password: 'test_password_123',
                        tenant: tenant)

      # Test that the user can obtain OAuth2 access token using their password
      post "/oauth/token", params: {
        grant_type: 'password',
        username: test_user.email,
        password: test_user.password,
        client_id: application.uid,
        client_secret: application.secret
      }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to include('access_token', 'token_type', 'expires_in', 'scope')
    end
  end

  describe "Facebook OAuth user session management" do
    before do
      sign_in facebook_user
    end

    it "maintains session for Facebook OAuth users" do
      get users_my_page_path
      expect(response).to have_http_status(:success)
    end

    it "allows Facebook OAuth users to sign out" do
      delete destroy_user_session_path
      expect(response).to have_http_status(:redirect)
      expect(controller.current_user).to be_nil
    end
  end

  describe "Facebook OAuth user profile" do
    before do
      sign_in facebook_user
    end

    it "displays Facebook OAuth user information" do
      get users_my_page_path
      expect(response.body).to include(facebook_user.email)
      expect(response.body).to include(facebook_user.name)
      expect(response.body).to include("Signed in via Facebook")
    end
  end
end 