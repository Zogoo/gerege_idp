class Users::MyPageController < ApplicationController
  before_action :authenticate_user!

  def show
  end
end
