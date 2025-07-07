require 'rails_helper'

RSpec.describe "api/v1/users/new", type: :view do
  before(:each) do
    assign(:api_v1_user, User.new())
  end

  it "renders new api/v1_user form" do
    render

    assert_select "form[action=?][method=?]", api_v1_users_path, "post" do
    end
  end
end
