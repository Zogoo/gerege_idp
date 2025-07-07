require 'rails_helper'

RSpec.describe "OmniAuth Callbacks", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:tenant) { create(:tenant, tenant_mode: :single) }
  let(:facebook_uid) { "123456789012345" }
  let(:facebook_email) { "user@example.com" }
  let(:facebook_name) { "John Doe" }
  let(:facebook_image) { "https://graph.facebook.com/123456789012345/picture" }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_tenant).and_return(tenant)
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
  end

  describe "GET /users/auth/facebook/callback" do
    context "when OAuth succeeds" do
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

      before do
        OmniAuth.config.mock_auth[:facebook] = auth_hash
      end

      context "when user exists" do
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
          get "/users/auth/facebook/callback"
          
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(users_my_page_path)
          expect(flash[:notice]).to eq("Successfully authenticated from Facebook account.")
        end
      end

      context "when user does not exist" do
        it "creates new user and signs them in" do
          expect {
            get "/users/auth/facebook/callback"
          }.to change(User, :count).by(1)

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(users_my_page_path)
          expect(flash[:notice]).to eq("Successfully authenticated from Facebook account.")
          
          user = User.find_by(provider: 'facebook', uid: facebook_uid)
          expect(user).to be_present
          expect(user.email).to eq(facebook_email)
          expect(user.name).to eq(facebook_name)
          expect(user.image).to eq(facebook_image)
          expect(user.tenant).to eq(tenant)
        end
      end
    end

    context "when OAuth fails" do
      it "redirects to registration with error" do
        OmniAuth.config.mock_auth[:facebook] = :invalid_credentials
        
        get "/users/auth/facebook/callback"
        
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end 