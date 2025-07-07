require 'rails_helper'

RSpec.describe "api/v1/users/show", type: :view do
  before(:each) do
    assign(:api_v1_user, create(:user))
  end

  it "renders attributes in <p>" do
    render
  end
end
