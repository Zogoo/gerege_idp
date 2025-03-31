require 'rails_helper'

RSpec.describe "Users::MyPages", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/users/my_page/show"
      expect(response).to have_http_status(:success)
    end
  end

end
