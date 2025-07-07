require 'rails_helper'

RSpec.describe "Users::MyPages", type: :request do
  describe "GET /show" do
    it "returns http success" do
      tenant = FactoryBot.create(:tenant)
      user = FactoryBot.create(:user, tenant: tenant)
      sign_in user
      get "/users/my_page"
      expect(response).to have_http_status(:success)
    end
  end

end
