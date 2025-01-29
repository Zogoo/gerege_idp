require 'rails_helper'

RSpec.describe "api/v1/users/edit", type: :view do
  let(:api_v1_user) {
    Api::V1::User.create!()
  }

  before(:each) do
    assign(:api_v1_user, api_v1_user)
  end

  it "renders the edit api/v1_user form" do
    render

    assert_select "form[action=?][method=?]", api/v1_user_path(api_v1_user), "post" do
    end
  end
end
