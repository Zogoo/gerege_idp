require 'rails_helper'

RSpec.describe "OAuth2 Password Grant Flow", type: :request do
  let(:tenant) { create(:tenant, tenant_mode: :single) }
  let(:user) { create(:user, tenant: tenant, email: 'test@example.com', password: 'password123') }
  let(:application) { create(:doorkeeper_application, redirect_uri: 'https://example.com/callback') }

  describe "Password Grant Authentication" do
    describe "POST /oauth/token with password grant" do
      context "when client app authenticates user with valid credentials" do
        it "successfully authenticates user and returns access token" do
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
          expect(json['access_token']).to be_present
          expect(json['expires_in']).to be_present
        end

        it "returns access token with custom scopes when requested" do
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

        it "creates a valid access token that can be used for API calls" do
          post "/oauth/token", params: {
            grant_type: 'password',
            username: user.email,
            password: 'password123',
            client_id: application.uid,
            client_secret: application.secret
          }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          access_token = json['access_token']

          # Verify the token can be used to access protected resources
          get "/api/v1/me", headers: {
            "Authorization" => "Bearer #{access_token}",
            "Accept" => "application/json"
          }

          expect(response).to have_http_status(:success)
          me_json = JSON.parse(response.body)
          expect(me_json['id']).to eq(user.id)
          expect(me_json['email']).to eq(user.email)
        end
      end

      context "when client app provides invalid credentials" do
        it "rejects authentication with wrong password" do
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

        it "rejects authentication with non-existent user" do
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

        it "rejects authentication with invalid client credentials" do
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

      context "when client app provides incomplete parameters" do
        it "rejects request with missing grant_type" do
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

        it "rejects request with missing username" do
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

        it "rejects request with missing password" do
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

        it "rejects request with missing client_id" do
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

    describe "Complete OAuth2 Password Grant Flow" do
      it "allows client app to authenticate user and access protected resources" do
        # Step 1: Client app requests access token with user credentials
        post "/oauth/token", params: {
          grant_type: 'password',
          username: user.email,
          password: 'password123',
          client_id: application.uid,
          client_secret: application.secret
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        access_token = json['access_token']

        # Step 2: Client app uses access token to access protected API
        get "/api/v1/me", headers: {
          "Authorization" => "Bearer #{access_token}",
          "Accept" => "application/json"
        }

        expect(response).to have_http_status(:success)
        me_json = JSON.parse(response.body)
        expect(me_json['id']).to eq(user.id)
        expect(me_json['email']).to eq(user.email)

        # Step 3: Client app can access other protected resources
        get "/api/v1/users", headers: {
          "Authorization" => "Bearer #{access_token}",
          "Accept" => "application/json"
        }

        expect(response).to have_http_status(:success)
      end

      it "handles multiple authentication attempts correctly" do
        # First authentication
        post "/oauth/token", params: {
          grant_type: 'password',
          username: user.email,
          password: 'password123',
          client_id: application.uid,
          client_secret: application.secret
        }

        expect(response).to have_http_status(:success)
        first_token = JSON.parse(response.body)['access_token']

        # Second authentication (should work and return different token)
        post "/oauth/token", params: {
          grant_type: 'password',
          username: user.email,
          password: 'password123',
          client_id: application.uid,
          client_secret: application.secret
        }

        expect(response).to have_http_status(:success)
        second_token = JSON.parse(response.body)['access_token']

        # Both tokens should be valid and different
        expect(first_token).not_to eq(second_token)

        # Both tokens should work for API access
        get "/api/v1/me", headers: {
          "Authorization" => "Bearer #{first_token}",
          "Accept" => "application/json"
        }
        expect(response).to have_http_status(:success)

        get "/api/v1/me", headers: {
          "Authorization" => "Bearer #{second_token}",
          "Accept" => "application/json"
        }
        expect(response).to have_http_status(:success)
      end
    end

    describe "Token Validation and Security" do
      it "rejects expired tokens" do
        # Create an expired token
        expired_token = create(:doorkeeper_access_token, 
                              application: application, 
                              resource_owner_id: user.id,
                              expires_in: -1.hour)

        get "/api/v1/me", headers: {
          "Authorization" => "Bearer #{expired_token.token}",
          "Accept" => "application/json"
        }

        expect(response).to have_http_status(:unauthorized)
      end

      it "rejects revoked tokens" do
        # Create and revoke a token
        token = create(:doorkeeper_access_token, 
                      application: application, 
                      resource_owner_id: user.id)
        token.update!(revoked_at: Time.current)

        get "/api/v1/me", headers: {
          "Authorization" => "Bearer #{token.token}",
          "Accept" => "application/json"
        }

        expect(response).to have_http_status(:unauthorized)
      end

      it "validates token scopes correctly" do
        # Create token with limited scope
        limited_token = create(:doorkeeper_access_token, 
                              application: application, 
                              resource_owner_id: user.id,
                              scopes: 'read')

        # Token should work for read operations
        get "/api/v1/me", headers: {
          "Authorization" => "Bearer #{limited_token.token}",
          "Accept" => "application/json"
        }
        expect(response).to have_http_status(:success)
      end
    end
  end
end 