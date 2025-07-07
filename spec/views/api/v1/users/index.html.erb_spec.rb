require 'rails_helper'

RSpec.describe "api/v1/users/index", type: :view do
  before(:each) do
    tenant = FactoryBot.create(:tenant)
    assign(:api_v1_users, [
      create(:user),
      create(:user)
    ])
  end

  it "renders a list of api/v1/users" do
    render
    cell_selector = 'div>p'
  end
end
