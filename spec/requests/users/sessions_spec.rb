require 'rails_helper'

RSpec.describe "User Sessions", type: :request do
  let(:tenant) { create(:tenant, tenant_mode: :single) }
  let(:user) { create(:user, tenant: tenant, email: 'test@example.com', password: 'password123') }

  describe "POST /users/sign_in" do
    context "with valid credentials" do
      it "redirects to loading page" do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'password123'
          }
        }

        expect(response).to redirect_to(users_verify_session_path)
        expect(session[:after_sign_in_redirect]).to be_present
        expect(session[:after_sign_in_redirect]).to eq(users_my_page_path)
      end
    end

    context "with invalid credentials" do
      it "renders sign in form with errors" do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'wrongpassword'
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Sign in to your account')
      end
    end
  end

  describe "GET /users/verify_session" do
    context "when user is authenticated" do
      before do
        # Use a different approach to sign in the user
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'password123'
          }
        }
        follow_redirect!
      end

      it "shows loading page" do
        get users_verify_session_path
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Signing you in...')
        expect(response.body).to include('Please wait while we redirect you to your account.')
        # Should redirect to after_sign_in_path_for by default
        expect(response.body).to include(users_my_page_path)
        # Check that JavaScript is present
        expect(response.body).to include('window.location.replace')
        expect(response.body).to include('DOMContentLoaded')
      end
    end

    context "when user is not authenticated" do
      it "redirects to sign in" do
        get users_verify_session_path
        
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
