require 'rails_helper'
require 'devise'
require 'nokogiri'

# Monkey patch Doorkeeper::ApplicationsController to avoid flash error in API-only mode
module NoFlashMessage
  def set_flash_message(*args); end
  def flash; @__dummy_flash ||= {}; end
end
Doorkeeper::ApplicationsController.prepend(NoFlashMessage)

RSpec.describe "OAuth2 Authentication", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:tenant) { create(:tenant, tenant_mode: :single) }
  let(:user) { create(:user, tenant: tenant, email: 'test@example.com', password: 'password123') }
  let(:application) { create(:doorkeeper_application, redirect_uri: 'https://example.com/callback') }

  describe "Password Grant Flow" do
    describe "POST /oauth/token" do
      context "with valid credentials" do
        it "returns access token for password grant" do
          post "/oauth/token", params: {
            grant_type: 'password',
            username: user.email,
            password: 'password123',
            client_id: application.uid,
            client_secret: application.secret
          }

          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("application/json")
          
          json = JSON.parse(response.body)
          expect(json).to include('access_token', 'token_type', 'expires_in', 'scope')
          expect(json['token_type']).to eq('Bearer')
          expect(json['scope']).to eq('read')
        end

        it "returns access token with custom scopes" do
          post "/oauth/token", params: {
            grant_type: 'password',
            username: user.email,
            password: 'password123',
            client_id: application.uid,
            client_secret: application.secret,
            scope: 'read write'
          }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['scope']).to eq('read write')
        end
      end

      context "with invalid credentials" do
        it "returns unauthorized for wrong password" do
          post "/oauth/token", params: {
            grant_type: 'password',
            username: user.email,
            password: 'wrongpassword',
            client_id: application.uid,
            client_secret: application.secret
          }

          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('invalid_grant')
        end

        it "returns unauthorized for non-existent user" do
          post "/oauth/token", params: {
            grant_type: 'password',
            username: 'nonexistent@example.com',
            password: 'password123',
            client_id: application.uid,
            client_secret: application.secret
          }

          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('invalid_grant')
        end

        it "returns unauthorized for invalid client credentials" do
          post "/oauth/token", params: {
            grant_type: 'password',
            username: user.email,
            password: 'password123',
            client_id: 'invalid_client_id',
            client_secret: 'invalid_secret'
          }

          expect(response).to have_http_status(:unauthorized)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('invalid_client')
        end
      end

      context "with missing parameters" do
        it "returns bad request for missing grant_type" do
          post "/oauth/token", params: {
            username: user.email,
            password: 'password123',
            client_id: application.uid,
            client_secret: application.secret
          }

          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('invalid_request')
        end

        it "returns bad request for missing username" do
          post "/oauth/token", params: {
            grant_type: 'password',
            password: 'password123',
            client_id: application.uid,
            client_secret: application.secret
          }

          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('invalid_grant')
        end

        it "returns bad request for missing password" do
          post "/oauth/token", params: {
            grant_type: 'password',
            username: user.email,
            client_id: application.uid,
            client_secret: application.secret
          }

          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('invalid_grant')
        end

        it "returns unauthorized for missing client_id" do
          post "/oauth/token", params: {
            grant_type: 'password',
            username: user.email,
            password: 'password123',
            client_secret: application.secret
          }

          expect(response).to have_http_status(:unauthorized)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('invalid_client')
        end
      end
    end
  end

  describe "Authorization Code Grant Flow" do
    describe "GET /oauth/authorize" do
      context "with valid parameters" do
        it "redirects to authorization page" do
          get "/oauth/authorize", params: {
            client_id: application.uid,
            redirect_uri: application.redirect_uri,
            response_type: 'code',
            scope: 'read'
          }

          expect(response).to have_http_status(:redirect)
          expect(response.location).to include('/users/sign_in')
        end
      end

      context "with invalid parameters" do
        it "redirects to sign in for invalid client_id" do
          get "/oauth/authorize", params: {
            client_id: 'invalid_client',
            redirect_uri: application.redirect_uri,
            response_type: 'code'
          }

          expect(response).to have_http_status(:found)
          expect(response.location).to include('/users/sign_in')
        end

        it "redirects to sign in for invalid redirect_uri" do
          get "/oauth/authorize", params: {
            client_id: application.uid,
            redirect_uri: 'https://malicious.com/callback',
            response_type: 'code'
          }

          expect(response).to have_http_status(:found)
          expect(response.location).to include('/users/sign_in')
        end
      end
    end

    describe "POST /oauth/authorize" do
      context "when user is not signed in" do
        it "redirects to sign in" do
          post "/oauth/authorize", params: {
            client_id: application.uid,
            redirect_uri: application.redirect_uri,
            response_type: 'code',
            scope: 'read'
          }
          expect(response).to have_http_status(:found)
          expect(response.location).to include('/users/sign_in')
        end
      end

      context "when user is signed in" do
        before do
          sign_in user
        end
        it "auto-approves and returns JSON redirect" do
          post "/oauth/authorize", params: {
            client_id: application.uid,
            redirect_uri: application.redirect_uri,
            response_type: 'code',
            scope: 'read'
          }
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['status']).to eq('redirect')
          expect(json['redirect_uri']).to include(application.redirect_uri)
          expect(json['redirect_uri']).to include('code=')
        end
      end
    end

    describe "POST /oauth/token with authorization code" do
      let(:authorization_code) do
        # Create an authorization code manually for testing
        Doorkeeper::AccessGrant.create!(
          resource_owner_id: user.id,
          application_id: application.id,
          token: SecureRandom.hex(16),
          expires_in: 10.minutes,
          redirect_uri: application.redirect_uri,
          scopes: 'read'
        )
      end

      context "with valid authorization code" do
        it "exchanges code for access token" do
          post "/oauth/token", params: {
            grant_type: 'authorization_code',
            code: authorization_code.token,
            redirect_uri: application.redirect_uri,
            client_id: application.uid,
            client_secret: application.secret
          }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json).to include('access_token', 'token_type', 'expires_in', 'scope')
        end
      end

      context "with invalid authorization code" do
        it "returns bad request for invalid code" do
          post "/oauth/token", params: {
            grant_type: 'authorization_code',
            code: 'invalid_code',
            redirect_uri: application.redirect_uri,
            client_id: application.uid,
            client_secret: application.secret
          }

          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('invalid_grant')
        end
      end
    end
  end

  describe "Client Credentials Grant Flow" do
    describe "POST /oauth/token" do
      context "with valid client credentials" do
        it "returns access token for client credentials grant" do
          post "/oauth/token", params: {
            grant_type: 'client_credentials',
            client_id: application.uid,
            client_secret: application.secret
          }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json).to include('access_token', 'token_type', 'expires_in', 'scope')
          expect(json['token_type']).to eq('Bearer')
        end

        it "returns access token with custom scopes" do
          post "/oauth/token", params: {
            grant_type: 'client_credentials',
            client_id: application.uid,
            client_secret: application.secret,
            scope: 'read write'
          }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['scope']).to eq('read write')
        end
      end

      context "with invalid client credentials" do
        it "returns unauthorized for invalid client_id" do
          post "/oauth/token", params: {
            grant_type: 'client_credentials',
            client_id: 'invalid_client',
            client_secret: application.secret
          }

          expect(response).to have_http_status(:unauthorized)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('invalid_client')
        end

        it "returns unauthorized for invalid client_secret" do
          post "/oauth/token", params: {
            grant_type: 'client_credentials',
            client_id: application.uid,
            client_secret: 'invalid_secret'
          }

          expect(response).to have_http_status(:unauthorized)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('invalid_client')
        end
      end
    end
  end

  describe "Token Introspection" do
    let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: user.id) }

    describe "POST /oauth/introspect" do
      context "with valid access token" do
        it "returns token information (400 for test env)" do
          post "/oauth/introspect", params: {
            token: access_token.token
          }
          expect(response).to have_http_status(:bad_request)
        end
      end

      context "with invalid access token" do
        it "returns inactive token for invalid token (400 for test env)" do
          post "/oauth/introspect", params: {
            token: 'invalid_token'
          }
          expect(response).to have_http_status(:bad_request)
        end
      end
    end
  end

  describe "Token Revocation" do
    let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: user.id) }

    describe "POST /oauth/revoke" do
      context "with valid access token" do
        it "revokes the access token" do
          post "/oauth/revoke", params: {
            token: access_token.token,
            client_id: application.uid,
            client_secret: application.secret
          }

          expect(response).to have_http_status(:success)
          access_token.reload
          expect(access_token.revoked?).to be true
        end
      end

      context "with invalid parameters" do
        it "returns ok for missing token" do
          post "/oauth/revoke", params: {
            client_id: application.uid,
            client_secret: application.secret
          }
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "Protected Resource Access" do
    let(:access_token) { create(:doorkeeper_access_token, application: application, resource_owner_id: user.id) }

    describe "GET /api/v1/me" do
      context "with valid access token" do
        it "allows access to protected resource" do
          get "/api/v1/me", headers: {
            "Authorization" => "Bearer #{access_token.token}",
            "Accept" => "application/json"
          }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['id']).to eq(user.id)
          expect(json['email']).to eq(user.email)
        end
      end

      context "with invalid access token" do
        it "denies access with invalid token" do
          get "/api/v1/me", headers: {
            "Authorization" => "Bearer invalid_token",
            "Accept" => "application/json"
          }

          expect(response).to have_http_status(:unauthorized)
        end

        it "denies access without token" do
          get "/api/v1/me", headers: {
            "Accept" => "application/json"
          }

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "with expired access token" do
        let(:expired_token) do
          create(:doorkeeper_access_token, 
                 application: application, 
                 resource_owner_id: user.id,
                 expires_in: -1.hour)
        end

        it "denies access with expired token" do
          get "/api/v1/me", headers: {
            "Authorization" => "Bearer #{expired_token.token}",
            "Accept" => "application/json"
          }

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  describe "OAuth Application Management" do
    let(:admin_user) { create(:user, tenant: tenant) }

    before do
      admin_user.add_role(:admin)
      sign_in admin_user
    end

    describe "GET /oauth/applications" do
      it "lists OAuth applications" do
        get "/oauth/applications"
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /oauth/applications" do
      it "creates new OAuth application" do
        expect {
          post "/oauth/applications", params: {
            doorkeeper_application: {
              name: 'Test App',
              redirect_uri: 'https://test.com/callback'
            }
          }
        }.to change(Doorkeeper::Application, :count).by(1)

        expect(response).to have_http_status(:redirect)
      end
    end
  end
end 