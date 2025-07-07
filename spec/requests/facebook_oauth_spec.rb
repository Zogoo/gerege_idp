require 'rails_helper'

RSpec.describe "Facebook OAuth", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:tenant) { create(:tenant, tenant_mode: :single) }
  let(:facebook_uid) { "123456789012345" }
  let(:facebook_email) { "user@example.com" }
  let(:facebook_name) { "John Doe" }
  let(:facebook_image) { "https://graph.facebook.com/123456789012345/picture" }

  before do
    # Mock the current_tenant method
    allow_any_instance_of(ApplicationController).to receive(:current_tenant).and_return(tenant)
    # Set up OmniAuth test mode
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
  end

  describe "GET /users/auth/facebook/callback" do
    context "when user exists with Facebook OAuth" do
      let!(:existing_user) do
        create(:user, :facebook_oauth,
               provider: 'facebook',
               uid: facebook_uid,
               email: facebook_email,
               name: facebook_name,
               image: facebook_image,
               tenant: tenant)
      end

      it "signs in existing user" do
        # Mock OmniAuth response
        OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new({
          provider: 'facebook',
          uid: facebook_uid,
          info: {
            email: facebook_email,
            name: facebook_name,
            image: facebook_image
          }
        })

        get "/users/auth/facebook/callback"
        
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(users_my_page_path)
        expect(flash[:notice]).to eq("Successfully authenticated from Facebook account.")
      end
    end

    context "when user does not exist" do
      it "creates new user and signs them in" do
        # Mock OmniAuth response
        OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new({
          provider: 'facebook',
          uid: facebook_uid,
          info: {
            email: facebook_email,
            name: facebook_name,
            image: facebook_image
          }
        })

        expect {
          get "/users/auth/facebook/callback"
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(users_my_page_path)
        expect(flash[:notice]).to eq("Successfully authenticated from Facebook account.")

        # Verify user was created with correct attributes
        user = User.find_by(provider: 'facebook', uid: facebook_uid)
        expect(user).to be_present
        expect(user.email).to eq(facebook_email)
        expect(user.name).to eq(facebook_name)
        expect(user.image).to eq(facebook_image)
        expect(user.tenant).to eq(tenant)
      end
    end

    context "when OAuth fails" do
      it "redirects to sign in with error" do
        OmniAuth.config.mock_auth[:facebook] = :invalid_credentials

        get "/users/auth/facebook/callback"
        
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "User model" do
    describe ".from_omniauth" do
      let(:auth_hash) do
        OmniAuth::AuthHash.new({
          provider: 'facebook',
          uid: facebook_uid,
          info: {
            email: facebook_email,
            name: facebook_name,
            image: facebook_image
          }
        })
      end

      context "when user exists" do
        let!(:existing_user) do
          create(:user, :facebook_oauth,
                 provider: 'facebook',
                 uid: facebook_uid,
                 tenant: tenant)
        end

        it "returns existing user" do
          user = User.from_omniauth(auth_hash, tenant)
          expect(user).to eq(existing_user)
        end
      end

      context "when user does not exist" do
        it "creates new user" do
          expect {
            User.from_omniauth(auth_hash, tenant)
          }.to change(User, :count).by(1)

          user = User.find_by(provider: 'facebook', uid: facebook_uid)
          expect(user.email).to eq(facebook_email)
          expect(user.name).to eq(facebook_name)
          expect(user.image).to eq(facebook_image)
          expect(user.tenant).to eq(tenant)
          expect(user.provider).to eq('facebook')
          expect(user.uid).to eq(facebook_uid)
        end

        it "generates a random password" do
          user = User.from_omniauth(auth_hash, tenant)
          expect(user.password).to be_present
          expect(user.password.length).to be >= 20
        end
      end
    end
  end

  describe "OAuth links in views" do
    it "shows Facebook login link" do
      get new_user_session_path
      expect(response.body).to include("Sign in with Facebook")
    end
  end

  describe "OAuth integration with Doorkeeper" do
    let(:application) { create(:doorkeeper_application) }
    let(:user) { create(:user, :facebook_oauth, tenant: tenant) }

    before do
      sign_in user
    end

    it "allows OAuth users to obtain access tokens" do
      post "/oauth/token", params: {
        grant_type: 'password',
        username: user.email,
        password: user.password,
        client_id: application.uid,
        client_secret: application.secret
      }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to include('access_token', 'token_type', 'expires_in', 'scope')
    end
  end
end 